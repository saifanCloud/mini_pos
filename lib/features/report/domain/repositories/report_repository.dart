import '../entities/report_summary.dart';

/// Kontrak repository laporan penjualan (F9 & D2 PRD).
abstract class ReportRepository {
  /// Memuat ringkasan omzet dan riwayat transaksi dalam rentang waktu tertentu.
  /// Data hanya dibaca dari tabel transactions & snapshot — tanpa join ke master.
  Future<ReportSummary> getReportSummary({
    required DateTime startDate,
    required DateTime endDate,
  });
}

