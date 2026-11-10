import 'package:flutter/material.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(); // setup get_it

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

  runApp(const App());
}
