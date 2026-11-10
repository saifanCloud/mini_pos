import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../screens/payment_screen.dart';

/// Modal bottom sheet untuk melihat dan mengelola isi keranjang belanja kasir.
/// Sesuai F6 PRD:
/// - Mengubah qty dengan tombol plus dan minus.
/// - Qty 0 menghapus baris.
/// - Tombol kosongkan keranjang dengan konfirmasi dialog.
/// - Tombol Bayar menuju halaman placeholder (Tahap 11).
class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  /// Bantuan untuk membuka lembar keranjang belanja.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Keranjang
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keranjang (${state.totalItems})',
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

                // Daftar Item Keranjang
                Flexible(
                  child: state.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.remove_shopping_cart_outlined,
                                  size: 64,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Keranjang masih kosong',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: state.lines.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final line = state.lines[index];
                            final cartCubit = context.read<CartCubit>();

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama produk & Add-on terpilih
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (line.selectedAddons.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '+ ${line.selectedAddons.map((a) => a.name).join(', ')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.tertiary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        RupiahFormatter.format(line.unitPrice),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Pengatur Kuantitas (- / qty / +)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Tombol Minus (jika 1, ikon tong sampah untuk hapus)
                                    IconButton(
                                      iconSize: 18,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        line.qty == 1
                                            ? Icons.delete_outline
                                            : Icons.remove,
                                        color: line.qty == 1
                                            ? theme.colorScheme.error
                                            : null,
                                      ),
                                      onPressed: () =>
                                          cartCubit.decrementQty(index),
                                    ),
                                    Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 26),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${line.qty}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Tombol Plus (validasi stok B1 PRD)
                                    IconButton(
                                      iconSize: 18,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        final result =
                                            cartCubit.incrementQty(index);
                                        if (!result.isValid) {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                result.message ??
                                                    'Stok tidak mencukupi',
                                              ),
                                              backgroundColor:
                                                  Colors.red.shade700,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 8),

                                // Subtotal per baris
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    RupiahFormatter.format(line.subtotal),
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                if (state.isNotEmpty) ...[
                  const Divider(height: 1),

                  // Footer: Total & Tombol Bayar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pembayaran:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              RupiahFormatter.format(state.subtotal),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Tutup bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text(
                            'Bayar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<CartCubit>().clearCart();
      }
    });
  }
}

