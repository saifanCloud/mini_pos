import '../../../../core/database/database_helper.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

/// Implementasi [ProductRepository] menggunakan SQLite.
class ProductRepositoryImpl implements ProductRepository {
  final DatabaseHelper _dbHelper;

  ProductRepositoryImpl(this._dbHelper);

  @override
  Future<List<Product>> getProducts({int? categoryId}) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT p.id, p.category_id, p.name, p.price, p.stock, p.photo_path, p.is_deleted,
             c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.is_deleted = 0
    ''';
    List<dynamic> args = [];

    if (categoryId != null) {
      query += ' AND p.category_id = ?';
      args.add(categoryId);
    }

    query += ' ORDER BY p.name COLLATE NOCASE ASC';

    final productRows = await db.rawQuery(query, args);

    if (productRows.isEmpty) return [];

    // Ambil data pivot product_addons untuk produk-produk ini
    final addonRows = await db.query(
      'product_addons',
      columns: ['product_id', 'addon_id'],
    );

    final Map<int, List<int>> productAddonMap = {};
    for (final row in addonRows) {
      final pId = row['product_id'] as int;
      final aId = row['addon_id'] as int;
      productAddonMap.putIfAbsent(pId, () => []).add(aId);
    }

    return productRows.map((row) {
      final pId = row['id'] as int;
      return ProductModel.fromMap(
        row,
        addonIds: productAddonMap[pId] ?? [],
      );
    }).toList();
  }

  @override
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.category_id, p.name, p.price, p.stock, p.photo_path, p.is_deleted,
             c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ? AND p.is_deleted = 0
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;

    final addonRows = await db.query(
      'product_addons',
      columns: ['addon_id'],
      where: 'product_id = ?',
      whereArgs: [id],
    );

    final addonIds = addonRows.map((r) => r['addon_id'] as int).toList();
    return ProductModel.fromMap(rows.first, addonIds: addonIds);
  }

  @override
  Future<Product> createProduct({
    required String name,
    int? categoryId,
    required int price,
    required int stock,
    String? photoPath,
    List<int> addonIds = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Nama produk tidak boleh kosong');
    }
    if (price < 0) {
      throw Exception('Harga produk tidak boleh negatif');
    }
    if (stock < 0) {
      throw Exception('Stok produk tidak boleh negatif');
    }

    final db = await _dbHelper.database;

    return await db.transaction<Product>((txn) async {
      // 1. Simpan produk
      final id = await txn.insert('products', {
        'category_id': categoryId,
        'name': trimmedName,
        'price': price,
        'stock': stock,
        'photo_path': photoPath,
        'is_deleted': 0,
      });

      // 2. Simpan relasi add-on di tabel pivot product_addons
      for (final addonId in addonIds) {
        await txn.insert('product_addons', {
          'product_id': id,
          'addon_id': addonId,
        });
      }

      // Ambil nama kategori jika ada
      String? categoryName;
      if (categoryId != null) {
        final catRows = await txn.query(
          'categories',
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [categoryId],
          limit: 1,
        );
        if (catRows.isNotEmpty) {
          categoryName = catRows.first['name'] as String?;
        }
      }

      return ProductModel(
        id: id,
        categoryId: categoryId,
        categoryName: categoryName,
        name: trimmedName,
        price: price,
        stock: stock,
        photoPath: photoPath,
        addonIds: addonIds,
        isDeleted: false,
      );
    });
  }

  @override
  Future<void> updateProduct(
    Product product, {
    List<int>? addonIds,
  }) async {
    final trimmedName = product.name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Nama produk tidak boleh kosong');
    }
    if (product.price < 0) {
      throw Exception('Harga produk tidak boleh negatif');
    }
    if (product.stock < 0) {
      throw Exception('Stok produk tidak boleh negatif');
    }

    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Perbarui data produk
      await txn.update(
        'products',
        {
          'category_id': product.categoryId,
          'name': trimmedName,
          'price': product.price,
          'stock': product.stock,
          'photo_path': product.photoPath,
        },
        where: 'id = ?',
        whereArgs: [product.id],
      );

      // 2. Perbarui pivot add-on jika disediakan
      if (addonIds != null) {
        await txn.delete(
          'product_addons',
          where: 'product_id = ?',
          whereArgs: [product.id],
        );

        for (final addonId in addonIds) {
          await txn.insert('product_addons', {
            'product_id': product.id,
            'addon_id': addonId,
          });
        }
      }
    });
  }

  @override
  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    // Soft delete per F4 & B2 PRD
    await db.update(
      'products',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

