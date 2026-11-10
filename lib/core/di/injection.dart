import 'package:get_it/get_it.dart';

/// Service locator global. Gunakan `sl<T>()` untuk mengambil instance.
final GetIt sl = GetIt.instance;

/// Daftarkan semua dependency di sini.
/// Dipanggil sekali dari `main.dart` sebelum `runApp`.
Future<void> configureDependencies() async {
  // TODO(tahap-2): daftarkan DatabaseHelper
  // TODO(tahap-4): daftarkan AuthRepository, AuthCubit
  // dst per fitur
}
