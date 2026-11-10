import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../category/presentation/screens/master_data_screen.dart';
import '../../report/presentation/cubit/report_cubit.dart';
import '../../report/presentation/screens/report_tab_view.dart';
import '../../settings/presentation/screens/settings_tab_view.dart';
import 'cubit/cashier_cubit.dart';
import 'screens/cashier_view.dart';

/// Layar utama shell aplikasi dengan navigasi 4 tab:
/// Kasir, Produk, Laporan, dan Pengaturan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Ketika logout, arahkan kembali ke layar Login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle(_currentIndex)),
          centerTitle: true,
        ),
        body: _buildBody(_currentIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              context.read<CashierCubit>().loadData();
            } else if (index == 2) {
              context.read<ReportCubit>().loadReport();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Kasir',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Produk',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }

  String _appBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Kasir';
      case 1:
        return 'Master Data & Produk';
      case 2:
        return 'Laporan Penjualan';
      case 3:
        return 'Pengaturan';
      default:
        return 'Mini POS';
    }
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const CashierView();
      case 1:
        return const MasterDataScreen();
      case 2:
        return const ReportTabView();
      case 3:
        return const SettingsTabView();
      default:
        return const SizedBox.shrink();
    }
  }
}
