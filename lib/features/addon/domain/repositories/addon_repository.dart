import '../entities/addon.dart';

/// Kontrak repository untuk manajemen data add-on/topping.
abstract class AddonRepository {
  /// Mengambil semua add-on aktif (yang belum di-soft-delete).
  Future<List<Addon>> getAddons();

  /// Membuat add-on baru.
  Future<Addon> createAddon({
    required String name,
    required int price,
    required int stock,
  });

  /// Memperbarui data add-on (nama, harga, stok).
  Future<void> updateAddon(Addon addon);

  /// Menghapus add-on dengan soft delete (is_deleted = 1).
  /// Sesuai F5 & B2 PRD, data tidak dihapus fisik agar riwayat transaksi aman.
  Future<void> deleteAddon(int id);
}

