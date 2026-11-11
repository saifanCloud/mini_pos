import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/price_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../screens/payment_screen.dart';

/// Modal bottom sheet untuk melihat dan mengelola isi keranjang belanja kasir (Tahap B).
/// Sesuai F6 PRD & Bagian 12:
/// - Mengubah qty dengan tombol plus dan minus (area sentuh minimal 48x48 dp).
/// - Geser baris ke samping (swipe to dismiss) untuk menghapus item.
/// - Tombol kosongkan keranjang dengan dialog konfirmasi.
/// - Tombol Bayar besar yang mengarahkan ke layar pembayaran.
class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  /// Bantuan untuk membuka lembar keranjang belanja.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (_) => const CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
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

                // 1. Header Keranjang
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Keranjang Belanja (${state.totalItems})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Tombol Kosongkan dengan konfirmasi (F6 PRD)
                      if (state.isNotEmpty)
                        IconButton(
                          tooltip: 'Kosongkan Keranjang',
                          icon: Icon(
                            Icons.delete_sweep_outlined,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _confirmClearCart(context),
                        ),

                      IconButton(
                        tooltip: 'Tutup',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 2. Daftar Item Keranjang (Swipe to dismiss)
                Flexible(
                  child: state.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: EmptyState(
                            icon: Icons.remove_shopping_cart_outlined,
                            title: 'Keranjang Masih Kosong',
                            description:
                                'Pilih produk dari katalog untuk mulai menambahkan pesanan pelanggan.',
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          itemCount: state.lines.length,
                          separatorBuilder: (_, _) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final line = state.lines[index];
                            final cartCubit = context.read<CartCubit>();

                            // Geser ke samping untuk menghapus baris (Tahap B)
                            return Dismissible(
                              key: ValueKey('cart_line_${line.product.id}_${line.selectedAddons.map((a) => a.id).join("_")}_$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.white),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                cartCubit.removeLine(index);
                                AppSnackBar.showInfo(
                                  context,
                                  '${line.product.name} dihapus dari keranjang',
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Nama produk & Add-on terpilih
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (line.selectedAddons.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '+ ${line.selectedAddons.map((a) => a.name).join(', ')}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.colorScheme.tertiary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const SizedBox(height: 3),
                                        PriceText(
                                          line.unitPrice,
                                          size: PriceSize.small,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          isBold: false,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Pengatur Kuantitas (- / qty / +) dengan area ketuk >= 48 dp
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Tombol Minus
                                      IconButton(
                                        iconSize: 20,
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          line.qty == 1
                                              ? Icons.delete_outline
                                              : Icons.remove_circle_outline,
                                          color: line.qty == 1
                                              ? theme.colorScheme.error
                                              : theme.colorScheme.primary,
                                        ),
                                        onPressed: () =>
                                            cartCubit.decrementQty(index),
                                      ),
                                      Container(
                                        constraints: const BoxConstraints(minWidth: 26),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${line.qty}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      // Tombol Plus (validasi stok B1 PRD)
                                      IconButton(
                                        iconSize: 20,
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: theme.colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          final result =
                                              cartCubit.incrementQty(index);
                                          if (!result.isValid) {
                                            AppSnackBar.showError(
                                              context,
                                              result.message ??
                                                  'Stok tidak mencukupi',
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: AppSpacing.sm),

                                  // Subtotal per baris
                                  SizedBox(
                                    width: 78,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: PriceText(
                                        line.subtotal,
                                        size: PriceSize.small,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                if (state.isNotEmpty) ...[
                  const Divider(height: 1),

                  // 3. Footer: Total & Tombol Bayar
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Belanja:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PriceText(
                              state.subtotal,
                              size: PriceSize.large,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          height: 52,
                          icon: Icons.payments_outlined,
                          label: 'Lanjut ke Pembayaran',
                          onPressed: () {
                            Navigator.pop(context); // Tutup bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text(
          'Semua item di dalam keranjang belanja akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<CartCubit>().clearCart();
        AppSnackBar.showInfo(context, 'Keranjang belanja dikosongkan');
      }
    });
  }
}
