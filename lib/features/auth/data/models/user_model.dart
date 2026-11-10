import '../../domain/entities/user.dart';

/// Model untuk mengonversi data antara database (Map) dan entity [User].
/// Hanya layer data yang boleh menggunakan class ini.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.createdAt,
  });

  /// Buat [UserModel] dari baris hasil query database.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      username: map['username'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  /// Konversi ke Map untuk disimpan ke database.
  /// Tidak menyertakan [id] agar AUTOINCREMENT bekerja pada INSERT.
  /// [passwordHash] wajib diisi saat INSERT; tidak disimpan di entity.
  Map<String, dynamic> toMap({required String passwordHash}) {
    return {
      'name': name,
      'username': username,
      'password_hash': passwordHash,
      'created_at': createdAt,
    };
  }
}

