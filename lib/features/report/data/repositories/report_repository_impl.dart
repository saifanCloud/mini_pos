import '../../../../core/database/database_helper.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/repositories/report_repository.dart';

/// Implementasi [ReportRepository] menggunakan SQLite.
/// Seluruh data dibaca dari tabel transaksi dan snapshot (B2 PRD).
class ReportRepositoryImpl implements ReportRepository {
  final DatabaseHelper _dbHelper;

  ReportRepositoryImpl(this._dbHelper);

  @override
  Future<ReportSummary> getReportSummary() async {
    final db = await _dbHelper.database;

    // Query daftar transaksi terurut dari yang terbaru ke terlama (created_at DESC)
    // dan menghitung total unit item per transaksi lewat transaction_items (snapshot)
    final rows = await db.rawQuery('''
      SELECT t.id, t.cashier_name, t.total, t.created_at,
             COALESCE(SUM(ti.qty), 0) AS total_items
      FROM transactions t
      LEFT JOIN transaction_items ti ON t.id = ti.transaction_id
      GROUP BY t.id
      ORDER BY t.created_at DESC, t.id DESC
    ''');

    int totalRevenue = 0;
    final List<TransactionHistoryItem> items = [];

    for (final r in rows) {
      final total = (r['total'] as int?) ?? 0;
      totalRevenue += total;

      items.add(
        TransactionHistoryItem(
          id: r['id'] as int,
          cashierName: (r['cashier_name'] as String?) ?? 'Kasir',
          total: total,
          totalItems: (r['total_items'] as int?) ?? 0,
          createdAt: (r['created_at'] as String?) ?? '',
        ),
      );
    }

    return ReportSummary(
      totalRevenue: totalRevenue,
      totalTransactions: items.length,
      transactions: items,
    );
  }
}

