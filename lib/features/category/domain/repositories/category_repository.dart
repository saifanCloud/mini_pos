import '../entities/category.dart';

/// Kontrak repository untuk manajemen data kategori.
abstract class CategoryRepository {
  /// Mengambil semua daftar kategori yang ada.
  Future<List<Category>> getCategories();

  /// Membuat kategori baru.
  /// Melempar [Exception] jika nama kosong atau sudah terdaftar.
  Future<Category> createCategory(String name);

  /// Memperbarui nama kategori.
  /// Melempar [Exception] jika nama kosong atau duplikat dengan kategori lain.
  Future<void> updateCategory(Category category);

  /// Menghapus kategori berdasarkan [id].
  /// Sesuai F3 PRD, produk dalam kategori ini tidak ikut terhapus
  /// (foreign key ON DELETE SET NULL).
  Future<void> deleteCategory(int id);
}

