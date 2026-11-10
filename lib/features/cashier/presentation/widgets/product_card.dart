import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/image_storage.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../product/domain/entities/product.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cashier_cubit.dart';
import 'addon_selection_bottom_sheet.dart';

/// Kartu item produk pada grid layar kasir (F6 PRD).
/// - 1 ketuk untuk produk tanpa add-on langsung menambah 1 ke keranjang.
/// - Produk dengan add-on membuka modal bottom sheet pemilihan add-on.
/// - Sisa stok 0 tampil nonaktif dengan badge "Habis".
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
    final hasAddons = product.addonIds.isNotEmpty;

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOutOfStock
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Opacity(
          opacity: isOutOfStock ? 0.55 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Gambar / Foto Produk
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildProductImage(theme),

                    // Label "Habis" jika stok 0
                    if (isOutOfStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(6),
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

                    // Indikator Add-on jika produk memiliki add-on
                    if (hasAddons && !isOutOfStock)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
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

              // Bagian Informasi Produk
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Produk
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Harga Jual
                    Text(
                      RupiahFormatter.format(product.price),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Sisa Stok
                    Text(
                      isOutOfStock ? 'Stok: 0' : 'Sisa: ${product.stock}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOutOfStock
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isOutOfStock ? FontWeight.bold : FontWeight.normal,
                      ),
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok ${product.name} habis'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Stok tidak mencukupi'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
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
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.fastfood_outlined,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          size: 36,
        ),
      ),
    );
  }
}

