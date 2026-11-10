import '../../../../core/database/database_helper.dart';
import '../../domain/entities/addon.dart';
import '../../domain/repositories/addon_repository.dart';
import '../models/addon_model.dart';

/// Implementasi [AddonRepository] menggunakan SQLite.
class AddonRepositoryImpl implements AddonRepository {
  final DatabaseHelper _dbHelper;

  AddonRepositoryImpl(this._dbHelper);

  @override
  Future<List<Addon>> getAddons() async {
    final db = await _dbHelper.database;
    // Hanya tampilkan add-on yang belum di-soft-delete (is_deleted = 0)
    final rows = await db.query(
      'addons',
      where: 'is_deleted = 0',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => AddonModel.fromMap(e)).toList();
  }

  @override
  Future<Addon> createAddon({
    required String name,
    required int price,
    required int stock,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Nama add-on tidak boleh kosong');
    }
    if (price < 0) {
      throw Exception('Harga add-on tidak boleh negatif');
    }
    if (stock < 0) {
      throw Exception('Stok add-on tidak boleh negatif');
    }

    final db = await _dbHelper.database;

    // Periksa apakah sudah ada add-on aktif dengan nama yang sama
    final existing = await db.query(
      'addons',
      where: 'LOWER(name) = LOWER(?) AND is_deleted = 0',
      whereArgs: [trimmedName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('Add-on "$trimmedName" sudah ada');
    }

    final id = await db.insert('addons', {
      'name': trimmedName,
      'price': price,
      'stock': stock,
      'is_deleted': 0,
    });

    return AddonModel(
      id: id,
      name: trimmedName,
      price: price,
      stock: stock,
      isDeleted: false,
    );
  }

  @override
  Future<void> updateAddon(Addon addon) async {
    final trimmedName = addon.name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Nama add-on tidak boleh kosong');
    }
    if (addon.price < 0) {
      throw Exception('Harga add-on tidak boleh negatif');
    }
    if (addon.stock < 0) {
      throw Exception('Stok add-on tidak boleh negatif');
    }

    final db = await _dbHelper.database;

    // Periksa duplikasi nama dengan add-on aktif lainnya
    final existing = await db.query(
      'addons',
      where: 'LOWER(name) = LOWER(?) AND id != ? AND is_deleted = 0',
      whereArgs: [trimmedName, addon.id],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('Add-on "$trimmedName" sudah digunakan');
    }

    await db.update(
      'addons',
      {
        'name': trimmedName,
        'price': addon.price,
        'stock': addon.stock,
      },
      where: 'id = ?',
      whereArgs: [addon.id],
    );
  }

  @override
  Future<void> deleteAddon(int id) async {
    final db = await _dbHelper.database;
    // Soft delete: tandai is_deleted = 1 agar riwayat transaksi tidak rusak (F5 & B2 PRD)
    await db.update(
      'addons',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

