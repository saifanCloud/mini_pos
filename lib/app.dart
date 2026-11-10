import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'features/addon/presentation/cubit/addon_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/category/presentation/cubit/category_cubit.dart';
import 'features/product/presentation/cubit/product_cubit.dart';

/// Root aplikasi — MaterialApp dengan tema Material 3 dan Global BlocProviders.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => sl<AuthCubit>(),
        ),
        BlocProvider<CategoryCubit>(
          create: (_) => sl<CategoryCubit>(),
        ),
        BlocProvider<AddonCubit>(
          create: (_) => sl<AddonCubit>(),
        ),
        BlocProvider<ProductCubit>(
          create: (_) => sl<ProductCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Mini POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2), // biru kasir
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
