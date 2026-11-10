import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/category/data/repositories/category_repository_impl.dart';
import '../../features/category/domain/repositories/category_repository.dart';
import '../../features/category/presentation/cubit/category_cubit.dart';

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

  // Category
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl<DatabaseHelper>()),
  );
  sl.registerFactory<CategoryCubit>(
    () => CategoryCubit(sl<CategoryRepository>()),
  );

  // TODO(tahap-7): daftarkan AddonRepository, AddonCubit
  // TODO(tahap-8): daftarkan ProductRepository, ProductCubit
  // dst per fitur
}
