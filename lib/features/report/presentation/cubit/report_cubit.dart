import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/repositories/report_repository.dart';
import 'report_state.dart';

/// Cubit untuk mengelola pemuatan laporan omzet dan riwayat penjualan (F9 & D2 PRD).
class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;

  ReportCubit(this._reportRepository) : super(const ReportState());

  /// Mengatur jenis filter tanggal (Hari ini, 7 hari terakhir, Bulan ini, atau Kustom)
  /// lalu otomatis memuat ulang data laporan sesuai rentang waktu tersebut.
  Future<void> setFilter(
    ReportFilterType filterType, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    emit(
      state.copyWith(
        filterType: filterType,
        customStart: customStart,
        customEnd: customEnd,
      ),
    );
    await loadReport();
  }

  /// Memuat data laporan penjualan dari SQLite berdasarkan rentang waktu filter aktif.
  Future<void> loadReport() async {
    try {
      emit(state.copyWith(status: ReportStatus.loading));

      final range = state.activeDateRange;
      final summary = await _reportRepository.getReportSummary(
        startDate: range.start,
        endDate: range.end,
      );

      emit(
        state.copyWith(
          status: ReportStatus.loaded,
          summary: summary,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportStatus.error,
          errorMessage: 'Gagal memuat laporan: $e',
        ),
      );
    }
  }
}
