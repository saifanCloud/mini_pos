import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';

/// Service locator global. Gunakan `sl<T>()` untuk mengambil instance.
final GetIt sl = GetIt.instance;

/// Daftarkan semua dependency di sini.
/// Dipanggil sekali dari `main.dart` sebelum `runApp`.
Future<void> configureDependencies() async {
  // Database — singleton: satu instance dan satu koneksi selama app berjalan.
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);

  // TODO(tahap-4): daftarkan AuthRepository, AuthCubit
  // TODO(tahap-6): daftarkan CategoryRepository, CategoryCubit
  // dst per fitur
}
