import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../cubit/cashier_cubit.dart';
import '../cubit/cashier_state.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/product_card.dart';

/// Tampilan utama layar kasir (F6 PRD & Bagian 12 Pedoman UX).
/// - Kolom pencarian nama produk instan (real-time filtering) dengan tombol clear.
/// - Chip filter kategori mendatar satu baris (chip "Semua" di awal).
/// - Grid produk responsif adaptif dengan badge sisa stok dan feedback belanja.
/// - Bar keranjang belanja di bagian bawah dengan total berjalan dan tombol Bayar.
class CashierView extends StatefulWidget {
  const CashierView({super.key});

  @override
  State<CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends State<CashierView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Muat data kasir saat pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashierCubit>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. Kolom Pencarian Instan (F6 PRD)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<CashierCubit>().setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (val) {
                context.read<CashierCubit>().setSearchQuery(val);
                setState(() {});
              },
            ),
          ),

          // 2. Chip Filter Kategori (F6 PRD)
          BlocBuilder<CashierCubit, CashierState>(
            buildWhen: (prev, curr) =>
                prev.categories != curr.categories ||
                prev.selectedCategoryId != curr.selectedCategoryId,
            builder: (context, state) {
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    // Chip "Semua"
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: const Text('Semua'),
                        selected: state.selectedCategoryId == null,
                        onSelected: (_) {
                          context.read<CashierCubit>().selectCategory(null);
                        },
                      ),
                    ),

                    // Chip tiap kategori yang ada
                    ...state.categories.map((cat) {
                      final isSelected = state.selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (_) {
                            context.read<CashierCubit>().selectCategory(cat.id);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xs),

          // 3. Grid Katalog Produk (F6 PRD)
          Expanded(
            child: BlocBuilder<CashierCubit, CashierState>(
              builder: (context, state) {
                if (state.status == CashierStatus.loading &&
                    state.products.isEmpty) {
                  return const LoadingView(message: 'Memuat katalog produk...');
                }

                if (state.status == CashierStatus.error &&
                    state.products.isEmpty) {
                  return ErrorView(
                    message: state.errorMessage ?? 'Gagal memuat produk kasir',
                    onRetry: () => context.read<CashierCubit>().loadData(),
                  );
                }

                // Kondisi: Belum ada produk sama sekali di database
                if (state.products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum Ada Produk Aktif',
                    description:
                        'Tambahkan produk di tab Produk untuk mulai bertransaksi kasir.',
                  );
                }

                final filtered = state.filteredProducts;

                // Kondisi: Hasil pencarian atau filter kategori tidak ditemukan
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Produk Tidak Ditemukan',
                    description:
                        'Coba kata kunci lain atau pilih kategori "Semua" untuk melihat katalog.',
                    buttonText: 'Reset Pencarian',
                    onButtonPressed: () {
                      _searchController.clear();
                      context.read<CashierCubit>().setSearchQuery('');
                      context.read<CashierCubit>().selectCategory(null);
                      setState(() {});
                    },
                  );
                }

                // Grid Produk — adaptif dengan proteksi overflow:
                // 2 kolom mobile (<600), 3 kolom tablet (600-840), 4 kolom (>840)
                return RefreshIndicator(
                  onRefresh: () => context.read<CashierCubit>().loadData(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount =
                          width >= 840 ? 4 : width >= 600 ? 3 : 2;

                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.69,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: filtered[index]);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 4. Bar Keranjang Belanja Bawah (F6 PRD)
      bottomNavigationBar: const CartBottomBar(),
    );
  }
}
