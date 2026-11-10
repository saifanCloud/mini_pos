import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/report/domain/entities/report_summary.dart';
import 'package:mini_pos/features/report/domain/repositories/report_repository.dart';
import 'package:mini_pos/features/report/presentation/cubit/report_cubit.dart';
import 'package:mini_pos/features/report/presentation/cubit/report_state.dart';

class MockReportRepository implements ReportRepository {
  bool shouldFail = false;
  String failureMessage = 'Database error';

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
  Future<ReportSummary> getReportSummary() async {
    if (shouldFail) {
      throw Exception(failureMessage);
    }
    return summaryToReturn;
  }
}

void main() {
  group('ReportCubit Tests (Tahap 13a & F9 PRD)', () {
    late MockReportRepository mockRepository;
    late ReportCubit reportCubit;

    setUp(() {
      mockRepository = MockReportRepository();
      reportCubit = ReportCubit(mockRepository);
    });

    tearDown(() {
      reportCubit.close();
    });

    test('State awal ReportCubit memiliki ringkasan kosong', () {
      expect(reportCubit.state.status, ReportStatus.initial);
      expect(reportCubit.state.summary.isEmpty, isTrue);
      expect(reportCubit.state.summary.totalRevenue, 0);
      expect(reportCubit.state.summary.totalTransactions, 0);
    });

    test('loadReport sukses memuat total omzet dan riwayat transaksi', () async {
      await reportCubit.loadReport();

      expect(reportCubit.state.status, ReportStatus.loaded);
      expect(reportCubit.state.summary.totalRevenue, 75000);
      expect(reportCubit.state.summary.totalTransactions, 3);
      expect(reportCubit.state.summary.transactions.length, 3);
      expect(reportCubit.state.summary.transactions.first.id, 3);
      expect(reportCubit.state.summary.transactions.first.total, 25000);
    });

    test('loadReport menangani kondisi belum ada transaksi (empty state)',
        () async {
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
}

