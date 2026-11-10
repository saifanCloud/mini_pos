import 'package:flutter/material.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/di/injection.dart';
import 'features/auth/domain/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // TODO: hapus setelah dicek — cetak nama tabel dari sqlite_master
  final db = await DatabaseHelper.instance.database;
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
  );
  debugPrint('=== Tabel di database ===');
  for (final row in tables) {
    debugPrint('  ${row['name']}');
  }
  debugPrint('=========================');

  // TODO: hapus setelah dicek — uji register, login, sesi, logout
  await _debugAuthFlow();

  runApp(const App());
}

/// TODO: hapus setelah dicek — alur lengkap auth untuk verifikasi manual.
Future<void> _debugAuthFlow() async {
  final auth = sl<AuthRepository>();

  try {
    // 1. Register user baru
    final user = await auth.register('Budi Kasir', 'budi01', 'rahasia123');
    debugPrint('[AUTH] Register berhasil: ${user.name} (@${user.username})');

    // 2. Login dengan credential yang benar
    final loggedIn = await auth.login('budi01', 'rahasia123');
    debugPrint('[AUTH] Login berhasil: ${loggedIn.name}');

    // 3. Baca sesi aktif
    final current = await auth.getCurrentUser();
    debugPrint('[AUTH] Sesi aktif: ${current?.name ?? 'tidak ada'}');

    // 4. Logout
    await auth.logout();
    final afterLogout = await auth.getCurrentUser();
    debugPrint('[AUTH] Setelah logout: ${afterLogout?.name ?? 'tidak ada sesi ✓'}');

    // 5. Login dengan password salah — harus melempar exception
    try {
      await auth.login('budi01', 'passwordSalah');
    } catch (e) {
      debugPrint('[AUTH] Login gagal (diharapkan): $e');
    }

    // 6. Register dengan username yang sama — harus ditolak
    try {
      await auth.register('Budi Lain', 'budi01', 'password456');
    } catch (e) {
      debugPrint('[AUTH] Register duplikat ditolak (diharapkan): $e');
    }
  } catch (e) {
    debugPrint('[AUTH] Error tidak terduga: $e');
  }
}
