import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/image_storage.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/price_text.dart';
import '../../../product/domain/entities/product.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cashier_cubit.dart';
import 'addon_selection_bottom_sheet.dart';

/// Kartu item produk pada grid layar kasir (F6 PRD & Tahap B).
/// - 1 ketuk untuk produk tanpa add-on langsung menambah 1 ke keranjang.
/// - Produk dengan add-on membuka modal bottom sheet pemilihan add-on.
/// - Menampilkan badge jumlah item yang sudah ada di keranjang sebagai umpan balik ketukan.
/// - Indikator sisa stok dengan peringatan oranye saat menipis (<=3) dan label Habis saat stok 0.
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutOfStock = product.stock <= 0;
    final isLowStock = !isOutOfStock && product.stock <= 3;
    final hasAddons = product.addonIds.isNotEmpty;

    // Hitung berapa unit produk ini yang sudah ada di keranjang belanja
    final inCartCount = context.select<CartCubit, int>((cubit) {
      return cubit.state.lines
          .where((l) => l.product.id == product.id)
          .fold<int>(0, (sum, l) => sum + l.qty);
    });

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: inCartCount > 0
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : isOutOfStock
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: inCartCount > 0 ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Opacity(
          opacity: isOutOfStock ? 0.45 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Bagian Foto Produk & Badges
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildProductImage(theme),

                    // Badge Kuantitas di Keranjang (Umpan Balik Ketukan)
                    if (inCartCount > 0)
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '$inCartCount di keranjang',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Label "Habis" jika stok 0
                    if (isOutOfStock)
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: const Text(
                            'Habis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Indikator Add-on jika produk memiliki opsi varian
                    if (hasAddons && !isOutOfStock)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            '+ Add-on',
                            style: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Bagian Informasi Produk
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nama Produk (Maksimal 2 baris)
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Harga Jual (menggunakan PriceText)
                    PriceText(
                      product.price,
                      size: PriceSize.small,
                    ),
                    const SizedBox(height: 2),

                    // Sisa Stok dengan warna peringatan halus
                    Text(
                      isOutOfStock
                          ? 'Stok habis'
                          : isLowStock
                              ? 'Sisa: ${product.stock} (Menipis)'
                              : 'Stok: ${product.stock}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOutOfStock
                            ? theme.colorScheme.error
                            : isLowStock
                                ? Colors.orange.shade800
                                : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isLowStock || isOutOfStock
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (product.stock <= 0) {
      AppSnackBar.showError(context, 'Stok ${product.name} telah habis');
      return;
    }

    if (product.addonIds.isNotEmpty) {
      // Produk dengan add-on: buka bottom sheet
      final cashierCubit = context.read<CashierCubit>();
      final availableAddons = cashierCubit.getAddonsForProduct(product);

      AddonSelectionBottomSheet.show(
        context,
        product: product,
        availableAddons: availableAddons,
      );
    } else {
      // Produk tanpa add-on: langsung 1 ketukan masuk keranjang
      final result = context.read<CartCubit>().addToCart(product, []);

      if (!result.isValid) {
        // Tampilkan pesan validasi stok jika gagal (B1 PRD)
        AppSnackBar.showError(
          context,
          result.message ?? 'Stok tidak mencukupi',
        );
      }
    }
  }

  Widget _buildProductImage(ThemeData theme) {
    return FutureBuilder<String?>(
      future: ImageStorage.fullPath(product.photoPath),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path != null && File(path).existsSync()) {
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, _, _) => _buildPlaceholder(theme),
          );
        }
        return _buildPlaceholder(theme);
      },
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Center(
        child: Icon(
          Icons.fastfood_outlined,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          size: 36,
        ),
      ),
    );
  }
}
