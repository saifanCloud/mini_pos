import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cashier_cubit.dart';
import '../cubit/cashier_state.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/product_card.dart';

/// Tampilan utama layar kasir (F6 PRD & Bagian 12 Pedoman UX).
/// - Kolom pencarian nama produk instan (real-time filtering).
/// - Chip filter kategori mendatar (chip "Semua" di awal).
/// - Grid produk responsif dengan foto, nama, harga, dan sisa stok.
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // 1. Kolom Pencarian Instan (F6 PRD)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
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
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Chip "Semua"
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
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
                        padding: const EdgeInsets.only(right: 8),
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

          const SizedBox(height: 6),

          // 3. Grid Katalog Produk (F6 PRD)
          Expanded(
            child: BlocBuilder<CashierCubit, CashierState>(
              builder: (context, state) {
                if (state.status == CashierStatus.loading &&
                    state.products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.status == CashierStatus.error &&
                    state.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage ?? 'Gagal memuat produk',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () =>
                              context.read<CashierCubit>().loadData(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                // Kondisi: Belum ada produk sama sekali di database
                if (state.products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada produk aktif',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tambahkan produk di tab Produk untuk mulai bertransaksi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered = state.filteredProducts;

                // Kondisi: Hasil pencarian atau filter kategori tidak ditemukan
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 64,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Produk tidak ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Coba gunakan kata kunci lain atau pilih kategori Semua.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Grid Produk
                return RefreshIndicator(
                  onRefresh: () => context.read<CashierCubit>().loadData(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: filtered[index]);
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

