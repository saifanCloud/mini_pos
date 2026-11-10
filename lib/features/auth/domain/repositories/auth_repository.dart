import '../entities/user.dart';

/// Kontrak repository autentikasi.
/// Layer domain mendefinisikan antarmuka ini;
/// layer data menyediakan implementasinya.
abstract class AuthRepository {
  /// Daftarkan user baru.
  /// Lempar [Exception] jika [username] sudah dipakai.
  Future<User> register(String name, String username, String password);

  /// Login dengan [username] dan [password].
  /// Lempar [Exception] dengan pesan umum jika gagal.
  /// Jika sukses, simpan sesi ke tabel app_session.
  Future<User> login(String username, String password);

  /// Baca sesi aktif dari app_session.
  /// Kembalikan [User] jika ada sesi, atau null jika belum login.
  Future<User?> getCurrentUser();

  /// Hapus sesi aktif (logout).
  Future<void> logout();
}

