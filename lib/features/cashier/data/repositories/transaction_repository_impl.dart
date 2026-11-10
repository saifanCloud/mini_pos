import '../../../../core/database/database_helper.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/discount.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/cart_logic.dart';

/// Implementasi [TransactionRepository] menggunakan SQLite.
/// Seluruh proses pembayaran berjalan dalam SATU transaksi database atomik (B5 PRD).
class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepositoryImpl(this._dbHelper);

  @override
  Future<int> saveTransaction({
    required Cart cart,
    required CheckoutTotals totals,
    required int paid,
    required int changeAmount,
  }) async {
    if (cart.isEmpty) {
      throw Exception('Keranjang belanja kosong');
    }
    if (paid < totals.total) {
      throw Exception('Uang yang dibayarkan kurang dari total belanja');
    }

    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      // 1. Baca sesi kasir aktif dari app_session join users (B2 PRD snapshot)
      final sessionRows = await txn.rawQuery('''
        SELECT u.id, u.name 
        FROM app_session s
        JOIN users u ON s.user_id = u.id
        WHERE s.id = 1
      ''');

      int? cashierId;
      String cashierName = 'Kasir';
      if (sessionRows.isNotEmpty) {
        cashierId = sessionRows.first['id'] as int?;
        cashierName = (sessionRows.first['name'] as String?) ?? 'Kasir';
      }

      // 2. Baca snapshot store_settings (B2 PRD)
      final storeRows = await txn.query('store_settings', where: 'id = 1');
      String storeName = 'Toko Saya';
      String? storeAddress;
      if (storeRows.isNotEmpty) {
        storeName = (storeRows.first['store_name'] as String?) ?? 'Toko Saya';
        storeAddress = storeRows.first['address'] as String?;
      }

      // 3. Baca ulang stok produk terkini & validasi ulang atomik (B1 & B5 PRD)
      final productIds = cart.lines.map((l) => l.product.id).toSet();
      for (final pId in productIds) {
        final rows = await txn.query(
          'products',
          columns: ['id', 'name', 'stock', 'is_deleted'],
          where: 'id = ?',
          whereArgs: [pId],
        );

        if (rows.isEmpty || (rows.first['is_deleted'] as int) == 1) {
          throw Exception('Produk dengan ID $pId telah dihapus atau tidak tersedia');
        }

        final currentStock = rows.first['stock'] as int;
        final name = rows.first['name'] as String;
        final neededQty = CartLogic.produkTerpakai(cart.lines, pId);

        if (neededQty > currentStock) {
          throw Exception('Stok $name tidak mencukupi (sisa: $currentStock, dibutuhkan: $neededQty)');
        }
      }

      // 4. Baca ulang stok add-on terkini & validasi ulang atomik (B1 & B5 PRD)
      final addonIds = cart.lines
          .expand((l) => l.selectedAddons.map((a) => a.id))
          .toSet();

      for (final aId in addonIds) {
        final rows = await txn.query(
          'addons',
          columns: ['id', 'name', 'stock', 'is_deleted'],
          where: 'id = ?',
          whereArgs: [aId],
        );

        if (rows.isEmpty || (rows.first['is_deleted'] as int) == 1) {
          throw Exception('Add-on dengan ID $aId telah dihapus atau tidak tersedia');
        }

        final currentStock = rows.first['stock'] as int;
        final name = rows.first['name'] as String;
        final neededQty = CartLogic.addonTerpakai(cart.lines, aId);

        if (neededQty > currentStock) {
          throw Exception('Stok add-on $name tidak mencukupi (sisa: $currentStock, dibutuhkan: $neededQty)');
        }
      }

      // 5. Simpan baris transaksi utama ke tabel transactions (created_at waktu lokal ISO 8601)
      final nowIso = DateTime.now().toIso8601String();
      final transactionId = await txn.insert('transactions', {
        'cashier_id': cashierId,
        'cashier_name': cashierName,
        'store_name': storeName,
        'store_address': storeAddress,
        'subtotal': totals.subtotal,
        'discount_type': totals.discountType?.name,
        'discount_value': totals.discountValue,
        'discount_amount': totals.discountAmount,
        'total': totals.total,
        'paid': paid,
        'change_amount': changeAmount,
        'created_at': nowIso,
      });

      // 6. Simpan rincian item & add-on beserta snapshot nama dan harga (B2 PRD)
      for (final line in cart.lines) {
        final itemId = await txn.insert('transaction_items', {
          'transaction_id': transactionId,
          'product_id': line.product.id,
          'product_name': line.product.name,
          'unit_price': line.product.price,
          'qty': line.qty,
        });

        for (final addon in line.selectedAddons) {
          await txn.insert('transaction_item_addons', {
            'transaction_item_id': itemId,
            'addon_id': addon.id,
            'addon_name': addon.name,
            'unit_price': addon.price,
            'qty': line.qty,
          });
        }
      }

      // 7. Kurangi stok produk secara atomik dengan syarat stock >= ? (B5 PRD)
      final Map<int, int> productDeductions = {};
      for (final line in cart.lines) {
        productDeductions[line.product.id] =
            (productDeductions[line.product.id] ?? 0) + line.qty;
      }

      for (final entry in productDeductions.entries) {
        final pId = entry.key;
        final qty = entry.value;
        final affected = await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?',
          [qty, pId, qty],
        );
        if (affected == 0) {
          // Gagal mengurangi stok -> lempar exception agar seluruh transaksi di-rollback!
          throw Exception('Gagal memproses transaksi: stok produk ID $pId tidak mencukupi.');
        }
      }

      // 8. Kurangi stok add-on secara atomik dengan syarat stock >= ? (B5 PRD)
      final Map<int, int> addonDeductions = {};
      for (final line in cart.lines) {
        for (final addon in line.selectedAddons) {
          addonDeductions[addon.id] =
              (addonDeductions[addon.id] ?? 0) + line.qty;
        }
      }

      for (final entry in addonDeductions.entries) {
        final aId = entry.key;
        final qty = entry.value;
        final affected = await txn.rawUpdate(
          'UPDATE addons SET stock = stock - ? WHERE id = ? AND stock >= ?',
          [qty, aId, qty],
        );
        if (affected == 0) {
          // Gagal mengurangi stok add-on -> rollback!
          throw Exception('Gagal memproses transaksi: stok add-on ID $aId tidak mencukupi.');
        }
      }

      return transactionId;
    });
  }

  @override
  Future<TransactionEntity?> getTransactionById(int id) async {
    final db = await _dbHelper.database;

    final txRows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (txRows.isEmpty) return null;
    final txMap = txRows.first;

    // Ambil transaction_items
    final itemRows = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );

    final List<TransactionItemEntity> items = [];
    for (final itemMap in itemRows) {
      final itemId = itemMap['id'] as int;

      // Ambil add-on untuk item ini
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
          transactionId: id,
          productId: itemMap['product_id'] as int?,
          productName: itemMap['product_name'] as String,
          unitPrice: itemMap['unit_price'] as int,
          qty: itemMap['qty'] as int,
          addons: addons,
        ),
      );
    }

    return TransactionEntity(
      id: id,
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

