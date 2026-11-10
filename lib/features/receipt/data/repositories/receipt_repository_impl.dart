import '../../../../core/database/database_helper.dart';
import '../../../cashier/domain/entities/transaction_entity.dart';
import '../../domain/repositories/receipt_repository.dart';

/// Implementasi [ReceiptRepository] menggunakan SQLite.
/// Sesuai B2 PRD: membaca HANYA dari tabel transaksi dan snapshot riwayat
/// (tanpa join ke tabel master produk atau add-on) agar struk tetap utuh selamanya.
class ReceiptRepositoryImpl implements ReceiptRepository {
  final DatabaseHelper _dbHelper;

  ReceiptRepositoryImpl(this._dbHelper);

  @override
  Future<TransactionEntity?> getReceipt(int transactionId) async {
    final db = await _dbHelper.database;

    // 1. Ambil baris utama transaksi dari tabel transactions
    final txRows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (txRows.isEmpty) return null;
    final txMap = txRows.first;

    // 2. Ambil baris item dari tabel snapshot transaction_items (tanpa join products)
    final itemRows = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );

    final List<TransactionItemEntity> items = [];
    for (final itemMap in itemRows) {
      final itemId = itemMap['id'] as int;

      // 3. Ambil baris add-on dari tabel snapshot transaction_item_addons (tanpa join addons)
      final addonRows = await db.query(
        'transaction_item_addons',
        where: 'transaction_item_id = ?',
        whereArgs: [itemId],
        orderBy: 'id ASC',
      );

      final addons = addonRows.map((a) {
        return TransactionItemAddonEntity(
          id: a['id'] as int?,
          transactionItemId: a['transaction_item_id'] as int?,
          addonId: a['addon_id'] as int?,
          addonName: a['addon_name'] as String,
          unitPrice: a['unit_price'] as int,
          qty: a['qty'] as int,
        );
      }).toList();

      items.add(
        TransactionItemEntity(
          id: itemId,
          transactionId: transactionId,
          productId: itemMap['product_id'] as int?,
          productName: itemMap['product_name'] as String,
          unitPrice: itemMap['unit_price'] as int,
          qty: itemMap['qty'] as int,
          addons: addons,
        ),
      );
    }

    return TransactionEntity(
      id: transactionId,
      cashierId: txMap['cashier_id'] as int?,
      cashierName: txMap['cashier_name'] as String,
      storeName: txMap['store_name'] as String,
      storeAddress: txMap['store_address'] as String?,
      subtotal: txMap['subtotal'] as int,
      discountType: txMap['discount_type'] as String?,
      discountValue: (txMap['discount_value'] as int?) ?? 0,
      discountAmount: (txMap['discount_amount'] as int?) ?? 0,
      total: txMap['total'] as int,
      paid: txMap['paid'] as int,
      changeAmount: txMap['change_amount'] as int,
      createdAt: txMap['created_at'] as String,
      items: items,
    );
  }
}
