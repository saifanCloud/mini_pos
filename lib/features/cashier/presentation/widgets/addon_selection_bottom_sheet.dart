import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/image_storage.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/price_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../addon/domain/entities/addon.dart';
import '../../../product/domain/entities/product.dart';
import '../cubit/cart_cubit.dart';

/// Modal bottom sheet untuk memilih add-on pada produk F&B / retail (Tahap B).
/// Sesuai F6 PRD:
/// - Kasir mencentang add-on yang diinginkan lalu menekan tombol "Tambah".
/// - Menampilkan nama produk, harga dasar, pilihan add-on, sisa stok, dan total unit berjalan.
class AddonSelectionBottomSheet extends StatefulWidget {
  final Product product;
  final List<Addon> availableAddons;

  const AddonSelectionBottomSheet({
    super.key,
    required this.product,
    required this.availableAddons,
  });

  /// Fungsi bantuan untuk menampilkan bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Product product,
    required List<Addon> availableAddons,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (_) => AddonSelectionBottomSheet(
        product: product,
        availableAddons: availableAddons,
      ),
    );
  }

  @override
  State<AddonSelectionBottomSheet> createState() =>
      _AddonSelectionBottomSheetState();
}

class _AddonSelectionBottomSheetState extends State<AddonSelectionBottomSheet> {
  final Set<int> _selectedAddonIds = {};

  int get _addonsTotalPrice {
    int sum = 0;
    for (final addon in widget.availableAddons) {
      if (_selectedAddonIds.contains(addon.id)) {
        sum += addon.price;
      }
    }
    return sum;
  }

  int get _unitTotalPrice => widget.product.price + _addonsTotalPrice;

  List<Addon> get _selectedAddons {
    return widget.availableAddons
        .where((a) => _selectedAddonIds.contains(a.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: mediaQuery.viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 1. Header Produk
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _buildProductThumbnail(theme),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          PriceText(
                            widget.product.price,
                            size: PriceSize.small,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 2. Judul Pilihan Add-on
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Add-on / Topping',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '${_selectedAddonIds.length} dipilih',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Daftar Checkbox Add-on
              Flexible(
                child: widget.availableAddons.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text(
                            'Tidak ada add-on aktif untuk produk ini',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: widget.availableAddons.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final addon = widget.availableAddons[index];
                          final isOutOfStock = addon.stock <= 0;
                          final isLowStock = !isOutOfStock && addon.stock <= 3;
                          final isSelected =
                              _selectedAddonIds.contains(addon.id);

                          return CheckboxListTile(
                            value: isSelected,
                            enabled: !isOutOfStock,
                            activeColor: theme.colorScheme.primary,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: 2,
                            ),
                            title: Text(
                              addon.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: isOutOfStock
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isOutOfStock
                                    ? theme.colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '+ ${RupiahFormatter.format(addon.price)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Text('  •  '),
                                Text(
                                  isOutOfStock
                                      ? 'Stok habis'
                                      : isLowStock
                                          ? 'Sisa: ${addon.stock} (Menipis)'
                                          : 'Sisa stok: ${addon.stock}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOutOfStock
                                        ? theme.colorScheme.error
                                        : isLowStock
                                            ? Colors.orange.shade800
                                            : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isLowStock || isOutOfStock
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            onChanged: isOutOfStock
                                ? null
                                : (bool? checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedAddonIds.add(addon.id);
                                      } else {
                                        _selectedAddonIds.remove(addon.id);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
              ),

              const Divider(height: 1),

              // 4. Footer: Subtotal Unit & Tombol Tambah
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Satuan:',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          PriceText(
                            _unitTotalPrice,
                            size: PriceSize.large,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    SizedBox(
                      width: 170,
                      child: PrimaryButton(
                        height: 52,
                        icon: Icons.add_shopping_cart_rounded,
                        label: 'Tambah',
                        onPressed: () {
                          // Tambahkan ke keranjang via CartCubit
                          final result = context.read<CartCubit>().addToCart(
                                widget.product,
                                _selectedAddons,
                              );

                          if (!result.isValid) {
                            // Tampilkan pesan error stok jika ditolak
                            AppSnackBar.showError(
                              context,
                              result.message ?? 'Stok tidak mencukupi',
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
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

  Widget _buildProductThumbnail(ThemeData theme) {
    return FutureBuilder<String?>(
      future: ImageStorage.fullPath(widget.product.photoPath),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path != null && File(path).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.file(
              File(path),
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder(theme),
            ),
          );
        }
        return _buildPlaceholder(theme);
      },
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: theme.colorScheme.primary,
        size: 26,
      ),
    );
  }
}
