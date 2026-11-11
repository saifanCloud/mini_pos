import '../../../../core/database/database_helper.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/repositories/report_repository.dart';

/// Implementasi repository laporan yang membaca dari SQLite (F9 & D2 PRD).
/// Semua data berasal dari tabel transactions dan snapshot — tidak join ke master.
class ReportRepositoryImpl implements ReportRepository {
  final DatabaseHelper _db;

  ReportRepositoryImpl(this._db);

  @override
  Future<ReportSummary> getReportSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db.database;

    // Format batas rentang ke ISO 8601 untuk dibandingkan dengan kolom created_at
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    // Hitung total omzet dan jumlah transaksi sukses dalam rentang waktu.
    // Memanfaatkan indeks idx_transactions_created_at untuk performa.
    final summaryResult = await db.rawQuery('''
      SELECT
        COALESCE(SUM(t.total), 0) AS total_revenue,
        COUNT(t.id)               AS total_transactions
      FROM transactions t
      WHERE t.created_at >= ? AND t.created_at <= ?
    ''', [startStr, endStr]);

    final totalRevenue =
        (summaryResult.first['total_revenue'] as num?)?.toInt() ?? 0;
    final totalTransactions =
        (summaryResult.first['total_transactions'] as int?) ?? 0;

    // Ambil riwayat transaksi terbaru di atas, bersama jumlah item per transaksi.
    final historyResult = await db.rawQuery('''
      SELECT
        t.id,
        t.cashier_name,
        t.total,
        COALESCE(SUM(ti.qty), 0) AS total_items,
        t.created_at
      FROM transactions t
      LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.created_at >= ? AND t.created_at <= ?
      GROUP BY t.id
      ORDER BY t.created_at DESC
    ''', [startStr, endStr]);

    final transactions = historyResult.map((row) {
      return TransactionHistoryItem(
        id: row['id'] as int,
        cashierName: row['cashier_name'] as String,
        total: row['total'] as int,
        totalItems: (row['total_items'] as num?)?.toInt() ?? 0,
        createdAt: row['created_at'] as String,
      );
    }).toList();

    return ReportSummary(
      totalRevenue: totalRevenue,
      totalTransactions: totalTransactions,
      transactions: transactions,
    );
  }
}

