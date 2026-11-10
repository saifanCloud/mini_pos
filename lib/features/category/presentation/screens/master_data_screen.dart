import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../cubit/category_cubit.dart';
import 'category_tab_view.dart';

/// Layar Master Data dengan TabBar (Kategori, Produk, Add-on).
class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoryCubit>(
      create: (_) => sl<CategoryCubit>(),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Kategori'),
                Tab(text: 'Produk'),
                Tab(text: 'Add-on'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const CategoryTabView(),
                  _buildPlaceholder(
                    context,
                    title: 'Kelola Produk',
                    subtitle: 'Fitur produk dan foto offline akan hadir di Tahap 8.',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildPlaceholder(
                    context,
                    title: 'Kelola Add-on / Topping',
                    subtitle: 'Fitur add-on dan stok tersendiri akan hadir di Tahap 7.',
                    icon: Icons.extension_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

