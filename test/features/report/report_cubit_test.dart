import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/report/domain/entities/report_filter.dart';
import 'package:mini_pos/features/report/domain/entities/report_summary.dart';
import 'package:mini_pos/features/report/domain/repositories/report_repository.dart';
import 'package:mini_pos/features/report/presentation/cubit/report_cubit.dart';
import 'package:mini_pos/features/report/presentation/cubit/report_state.dart';

class MockReportRepository implements ReportRepository {
  bool shouldFail = false;
  String failureMessage = 'Database error';
  DateTime? lastStartDate;
  DateTime? lastEndDate;

  ReportSummary summaryToReturn = const ReportSummary(
    totalRevenue: 75000,
    totalTransactions: 3,
    transactions: [
      TransactionHistoryItem(
        id: 3,
        cashierName: 'Budi',
        total: 25000,
        totalItems: 2,
        createdAt: '2026-11-10T16:00:00.000',
      ),
      TransactionHistoryItem(
        id: 2,
        cashierName: 'Budi',
        total: 30000,
        totalItems: 2,
        createdAt: '2026-11-10T15:00:00.000',
      ),
      TransactionHistoryItem(
        id: 1,
        cashierName: 'Budi',
        total: 20000,
        totalItems: 1,
        createdAt: '2026-11-10T14:00:00.000',
      ),
    ],
  );

  @override
  Future<ReportSummary> getReportSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    lastStartDate = startDate;
    lastEndDate = endDate;
    if (shouldFail) {
      throw Exception(failureMessage);
    }
    return summaryToReturn;
  }
}

void main() {
  group('ReportCubit & Filter Tests (Tahap 13a, 13b, F9, D2 PRD)', () {
    late MockReportRepository mockRepository;
    late ReportCubit reportCubit;

    setUp(() {
      mockRepository = MockReportRepository();
      reportCubit = ReportCubit(mockRepository);
    });

    tearDown(() {
      reportCubit.close();
    });

    test('State awal ReportCubit: filter Hari ini dan ringkasan kosong', () {
      expect(reportCubit.state.status, ReportStatus.initial);
      expect(reportCubit.state.filterType, ReportFilterType.today);
      expect(reportCubit.state.summary.isEmpty, isTrue);
      expect(reportCubit.state.summary.totalRevenue, 0);
      expect(reportCubit.state.summary.totalTransactions, 0);
    });

    test('loadReport memanggil repository dengan rentang tanggal hari ini', () async {
      await reportCubit.loadReport();

      expect(reportCubit.state.status, ReportStatus.loaded);
      expect(mockRepository.lastStartDate, isNotNull);
      expect(mockRepository.lastEndDate, isNotNull);

      // Verifikasi batas waktu jam:menit:detik
      expect(mockRepository.lastStartDate!.hour, 0);
      expect(mockRepository.lastStartDate!.minute, 0);
      expect(mockRepository.lastStartDate!.second, 0);
      expect(mockRepository.lastEndDate!.hour, 23);
      expect(mockRepository.lastEndDate!.minute, 59);
      expect(mockRepository.lastEndDate!.second, 59);

      expect(reportCubit.state.summary.totalRevenue, 75000);
      expect(reportCubit.state.summary.totalTransactions, 3);
      expect(reportCubit.state.summary.transactions.length, 3);
    });

    test('setFilter mengubah jenis filter dan memuat ulang laporan', () async {
      await reportCubit.setFilter(ReportFilterType.last7Days);

      expect(reportCubit.state.filterType, ReportFilterType.last7Days);
      expect(reportCubit.state.status, ReportStatus.loaded);
      expect(mockRepository.lastStartDate, isNotNull);
      expect(mockRepository.lastEndDate, isNotNull);

      // 7 hari (start = today - 6 hari)
      final difference = mockRepository.lastEndDate!.difference(mockRepository.lastStartDate!).inDays;
      expect(difference, 6);
    });

    test('setFilter custom menyimpan customStart dan customEnd', () async {
      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 5);

      await reportCubit.setFilter(
        ReportFilterType.custom,
        customStart: start,
        customEnd: end,
      );

      expect(reportCubit.state.filterType, ReportFilterType.custom);
      expect(mockRepository.lastStartDate!.year, 2026);
      expect(mockRepository.lastStartDate!.month, 11);
      expect(mockRepository.lastStartDate!.day, 1);
      expect(mockRepository.lastEndDate!.day, 5);
    });

    test('loadReport menangani kondisi belum ada transaksi (empty state)', () async {
      mockRepository.summaryToReturn = const ReportSummary(
        totalRevenue: 0,
        totalTransactions: 0,
        transactions: [],
      );

      await reportCubit.loadReport();

      expect(reportCubit.state.status, ReportStatus.loaded);
      expect(reportCubit.state.summary.isEmpty, isTrue);
      expect(reportCubit.state.summary.totalRevenue, 0);
      expect(reportCubit.state.summary.totalTransactions, 0);
    });

    test('loadReport menangani kegagalan query database', () async {
      mockRepository.shouldFail = true;
      mockRepository.failureMessage = 'Koneksi database terputus';

      await reportCubit.loadReport();

      expect(reportCubit.state.status, ReportStatus.error);
      expect(reportCubit.state.errorMessage, contains('Koneksi database terputus'));
    });
  });

  group('DateRangeHelper Tests (D2 PRD)', () {
    final fixedNow = DateTime(2026, 11, 10, 14, 30, 0);

    test('startOfDay dan endOfDay tepat pada 00:00:00 dan 23:59:59.999', () {
      final start = DateRangeHelper.startOfDay(fixedNow);
      final end = DateRangeHelper.endOfDay(fixedNow);

      expect(start, DateTime(2026, 11, 10, 0, 0, 0, 0));
      expect(end, DateTime(2026, 11, 10, 23, 59, 59, 999));
    });

    test('getDateRange today mengembalikan awal dan akhir hari yang sama', () {
      final range = DateRangeHelper.getDateRange(ReportFilterType.today, now: fixedNow);
      expect(range.start, DateTime(2026, 11, 10, 0, 0, 0, 0));
      expect(range.end, DateTime(2026, 11, 10, 23, 59, 59, 999));
    });

    test('getDateRange last7Days mengembalikan 7 hari kalender (H-6 hingga H)', () {
      final range = DateRangeHelper.getDateRange(ReportFilterType.last7Days, now: fixedNow);
      expect(range.start, DateTime(2026, 11, 4, 0, 0, 0, 0));
      expect(range.end, DateTime(2026, 11, 10, 23, 59, 59, 999));
    });

    test('getDateRange thisMonth mengembalikan dari tgl 1 hingga tgl akhir bulan', () {
      final range = DateRangeHelper.getDateRange(ReportFilterType.thisMonth, now: fixedNow);
      expect(range.start, DateTime(2026, 11, 1, 0, 0, 0, 0));
      // November punya 30 hari
      expect(range.end, DateTime(2026, 11, 30, 23, 59, 59, 999));
    });

    test('getDateRange custom mengembalikan rentang tanggal yang ditentukan', () {
      final customStart = DateTime(2026, 10, 15);
      final customEnd = DateTime(2026, 10, 20);

      final range = DateRangeHelper.getDateRange(
        ReportFilterType.custom,
        customStart: customStart,
        customEnd: customEnd,
        now: fixedNow,
      );

      expect(range.start, DateTime(2026, 10, 15, 0, 0, 0, 0));
      expect(range.end, DateTime(2026, 10, 20, 23, 59, 59, 999));
    });
  });
}

