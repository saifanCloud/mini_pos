import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Utilitas hash dan verifikasi password menggunakan salt acak + SHA-256.
/// Format simpan di database: "salt:hash" (keduanya hex string).
/// Tidak pernah menyimpan password dalam teks asli (sesuai F2 PRD).
class PasswordHasher {
  static final _random = Random.secure();

  /// Buat hash dari [password].
  /// Setiap pemanggilan menghasilkan salt baru sehingga hash selalu berbeda.
  /// Kembalikan string "salt:hash" yang siap disimpan ke database.
  static String hash(String password) {
    final salt = _generateSalt();
    final hash = _sha256(salt + password);
    return '$salt:$hash';
  }

  /// Verifikasi [password] terhadap [stored] (string "salt:hash" dari database).
  /// Kembalikan true jika password cocok, false jika tidak.
  static bool verify(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final expectedHash = parts[1];
    final actualHash = _sha256(salt + password);
    return actualHash == expectedHash;
  }

  /// Hasilkan salt acak 16 byte sebagai hex string (32 karakter).
  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hitung SHA-256 dari [input] dan kembalikan sebagai hex string.
  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

