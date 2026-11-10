import '../../../../core/database/database_helper.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

/// Implementasi [CategoryRepository] menggunakan SQLite.
class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper _dbHelper;

  CategoryRepositoryImpl(this._dbHelper);

  @override
  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => CategoryModel.fromMap(e)).toList();
  }

  @override
  Future<Category> createCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Nama kategori tidak boleh kosong');
    }

    final db = await _dbHelper.database;

    // Validasi duplikasi nama (case-insensitive)
    final existing = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [trimmedName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('Kategori "$trimmedName" sudah ada');
    }

    final id = await db.insert('categories', {
      'name': trimmedName,
    });

    return CategoryModel(id: id, name: trimmedName);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final trimmedName = category.name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Nama kategori tidak boleh kosong');
    }

    final db = await _dbHelper.database;

    // Validasi duplikasi nama dengan ID berbeda
    final existing = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [trimmedName, category.id],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('Kategori "$trimmedName" sudah digunakan');
    }

    await db.update(
      'categories',
      {'name': trimmedName},
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    // Foreign key ON DELETE SET NULL pada tabel products secara otomatis
    // mengubah category_id produk terkait menjadi NULL.
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

