import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/password_hasher.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Implementasi [AuthRepository] menggunakan SQLite (sqflite).
class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _dbHelper;

  AuthRepositoryImpl(this._dbHelper);

  // ─── Register ────────────────────────────────────────────────────────────────

  @override
  Future<User> register(String name, String username, String password) async {
    final db = await _dbHelper.database;

    // Hash password sebelum disimpan — tidak pernah simpan teks asli (F2 PRD).
    final passwordHash = PasswordHasher.hash(password);
    final now = DateTime.now().toIso8601String();

    try {
      final id = await db.insert(
        'users',
        {
          'name': name,
          'username': username,
          'password_hash': passwordHash,
          'created_at': now,
        },
        // Gagal jika username sudah ada (kolom UNIQUE di skema).
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      return UserModel(
        id: id,
        name: name,
        username: username,
        createdAt: now,
      );
    } on DatabaseException catch (e) {
      // UNIQUE constraint gagal → username sudah dipakai.
      if (e.isUniqueConstraintError()) {
        throw Exception('Username sudah dipakai, coba username lain');
      }
      throw Exception('Gagal mendaftar, coba lagi');
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────────────

  @override
  Future<User> login(String username, String password) async {
    final db = await _dbHelper.database;

    // Cari user berdasarkan username.
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    // Pesan error dibuat umum agar tidak membocorkan informasi (F2 PRD).
    if (rows.isEmpty) {
      throw Exception('Username atau password salah');
    }

    final userRow = rows.first;
    final storedHash = userRow['password_hash'] as String;

    if (!PasswordHasher.verify(password, storedHash)) {
      throw Exception('Username atau password salah');
    }

    final user = UserModel.fromMap(userRow as Map<String, dynamic>);

    // Simpan sesi — INSERT OR REPLACE menjamin id = 1 selalu (B8 skema).
    await db.insert(
      'app_session',
      {
        'id': 1,
        'user_id': user.id,
        'logged_in_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return user;
  }

  // ─── Get Current User ────────────────────────────────────────────────────────

  @override
  Future<User?> getCurrentUser() async {
    final db = await _dbHelper.database;

    // Baca app_session lalu ambil data user-nya.
    final rows = await db.rawQuery('''
      SELECT u.id, u.name, u.username, u.created_at
      FROM app_session s
      JOIN users u ON u.id = s.user_id
      WHERE s.id = 1
      LIMIT 1
    ''');

    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first as Map<String, dynamic>);
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    final db = await _dbHelper.database;
    // Hapus satu-satunya baris sesi (id = 1).
    await db.delete('app_session', where: 'id = ?', whereArgs: [1]);
  }
}

