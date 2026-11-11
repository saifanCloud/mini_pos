import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/addon/presentation/cubit/addon_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/cashier/presentation/cubit/cart_cubit.dart';
import 'features/cashier/presentation/cubit/cashier_cubit.dart';
import 'features/cashier/presentation/cubit/checkout_cubit.dart';
import 'features/category/presentation/cubit/category_cubit.dart';
import 'features/product/presentation/cubit/product_cubit.dart';
import 'features/report/presentation/cubit/report_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

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
        BlocProvider<CashierCubit>(
          create: (_) => sl<CashierCubit>(),
        ),
        BlocProvider<CartCubit>(
          create: (_) => sl<CartCubit>(),
        ),
        BlocProvider<CheckoutCubit>(
          create: (_) => sl<CheckoutCubit>(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>(),
        ),
        BlocProvider<ReportCubit>(
          create: (_) => sl<ReportCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Mini POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
