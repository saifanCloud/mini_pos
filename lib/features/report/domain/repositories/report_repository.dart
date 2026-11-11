import '../entities/report_summary.dart';

/// Kontrak repository untuk laporan penjualan dan riwayat transaksi (F9 & D2 PRD).
abstract class ReportRepository {
  /// Mengambil data ringkasan omzet, jumlah transaksi, dan daftar riwayat transaksi
  /// yang difilter antara [startDate] dan [endDate] berdasarkan kolom `created_at`.
  /// Murni membaca dari tabel transaksi dan snapshot (B2 PRD).
  Future<ReportSummary> getReportSummary({
    required DateTime startDate,
    required DateTime endDate,
  });
}
