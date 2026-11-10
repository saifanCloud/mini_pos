import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../../features/addon/data/repositories/addon_repository_impl.dart';
import '../../features/addon/domain/repositories/addon_repository.dart';
import '../../features/addon/presentation/cubit/addon_cubit.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/cashier/presentation/cubit/cart_cubit.dart';
import '../../features/cashier/presentation/cubit/cashier_cubit.dart';
import '../../features/category/data/repositories/category_repository_impl.dart';
import '../../features/category/domain/repositories/category_repository.dart';
import '../../features/category/presentation/cubit/category_cubit.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/presentation/cubit/product_cubit.dart';

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

  // Add-on
  sl.registerLazySingleton<AddonRepository>(
    () => AddonRepositoryImpl(sl<DatabaseHelper>()),
  );
  sl.registerFactory<AddonCubit>(
    () => AddonCubit(sl<AddonRepository>()),
  );

  // Product
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl<DatabaseHelper>()),
  );
  sl.registerFactory<ProductCubit>(
    () => ProductCubit(sl<ProductRepository>()),
  );

  // Cashier & Cart
  sl.registerFactory<CashierCubit>(
    () => CashierCubit(
      sl<ProductRepository>(),
      sl<CategoryRepository>(),
      sl<AddonRepository>(),
    ),
  );
  sl.registerLazySingleton<CartCubit>(
    () => CartCubit(),
  );
}
