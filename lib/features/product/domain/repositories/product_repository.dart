import '../entities/product.dart';

/// Kontrak repository untuk manajemen data produk dan relasi add-on.
abstract class ProductRepository {
  /// Mengambil semua produk aktif (is_deleted = 0).
  /// Dapat difilter berdasarkan [categoryId].
  Future<List<Product>> getProducts({int? categoryId});

  /// Mengambil produk tunggal beserta daftar addonIds-nya.
  Future<Product?> getProductById(int id);

  /// Membuat produk baru beserta relasi add-on di tabel pivot `product_addons`.
  Future<Product> createProduct({
    required String name,
    int? categoryId,
    required int price,
    required int stock,
    String? photoPath,
    List<int> addonIds = const [],
  });

  /// Memperbarui informasi produk dan relasi add-on.
  Future<void> updateProduct(
    Product product, {
    List<int>? addonIds,
  });

  /// Menghapus produk dengan soft delete (is_deleted = 1).
  /// Sesuai F4 & B2 PRD, data riwayat transaksi lama tetap aman.
  Future<void> deleteProduct(int id);
}

