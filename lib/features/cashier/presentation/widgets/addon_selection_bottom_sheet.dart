import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/image_storage.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../addon/domain/entities/addon.dart';
import '../../../product/domain/entities/product.dart';
import '../cubit/cart_cubit.dart';

/// Modal bottom sheet untuk memilih add-on pada produk F&B / retail.
/// Sesuai F6 PRD: kasir mencentang add-on yang diinginkan lalu menekan "Tambah".
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Produk
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildProductThumbnail(theme),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            RupiahFormatter.format(widget.product.price),
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
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

              // Judul Pilihan Add-on
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Text(
                      '${_selectedAddonIds.length} dipilih',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar Checkbox Add-on
              Flexible(
                child: widget.availableAddons.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Tidak ada add-on aktif untuk produk ini',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.availableAddons.length,
                        itemBuilder: (context, index) {
                          final addon = widget.availableAddons[index];
                          final isOutOfStock = addon.stock <= 0;
                          final isSelected =
                              _selectedAddonIds.contains(addon.id);

                          return CheckboxListTile(
                            value: isSelected,
                            enabled: !isOutOfStock,
                            activeColor: theme.colorScheme.primary,
                            title: Text(
                              addon.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                decoration: isOutOfStock
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isOutOfStock
                                    ? theme.colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '+ ${RupiahFormatter.format(addon.price)} • '
                              '${isOutOfStock ? "Stok Habis" : "Sisa stok: ${addon.stock}"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOutOfStock
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
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

              // Footer: Subtotal Unit & Tombol Tambah
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Satuan',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            RupiahFormatter.format(_unitTotalPrice),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        minimumSize: const Size(160, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Tambahkan ke keranjang via CartCubit
                        final result = context.read<CartCubit>().addToCart(
                              widget.product,
                              _selectedAddons,
                            );

                        if (!result.isValid) {
                          // Tampilkan pesan error stok jika ditolak
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.message ?? 'Stok tidak mencukupi',
                              ),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: 50,
              height: 50,
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
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: theme.colorScheme.primary,
        size: 24,
      ),
    );
  }
}

