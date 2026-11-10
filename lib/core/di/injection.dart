import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

/// Service locator global. Gunakan `sl<T>()` untuk mengambil instance.
final GetIt sl = GetIt.instance;

/// Daftarkan semua dependency di sini.
/// Dipanggil sekali dari `main.dart` sebelum `runApp`.
Future<void> configureDependencies() async {
  // Database — singleton: satu instance dan satu koneksi selama app berjalan.
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<DatabaseHelper>()),
  );
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(sl<AuthRepository>()),
  );

  // TODO(tahap-6): daftarkan CategoryRepository, CategoryCubit
  // TODO(tahap-7): daftarkan AddonRepository, AddonCubit
  // dst per fitur
}
