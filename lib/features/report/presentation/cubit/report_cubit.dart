import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/report_repository.dart';
import 'report_state.dart';

/// Cubit untuk mengelola pemuatan laporan omzet dan riwayat penjualan (F9 PRD).
class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;

  ReportCubit(this._reportRepository) : super(const ReportState());

  /// Memuat data laporan penjualan dari database SQLite.
  Future<void> loadReport() async {
    try {
      emit(state.copyWith(status: ReportStatus.loading));
      final summary = await _reportRepository.getReportSummary();
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

