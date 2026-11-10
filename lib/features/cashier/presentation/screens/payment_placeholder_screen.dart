import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// Halaman placeholder pembayaran (Tahap 10).
/// Fitur lengkap pembayaran (diskon, uang diterima, Quick Cash, kembalian,
/// dan transaksi atomik B5) akan diimplementasikan pada Tahap 11.
class PaymentPlaceholderScreen extends StatelessWidget {
  const PaymentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        centerTitle: true,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Informasi Tahap 11
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Placeholder Pembayaran (Tahap 10)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fitur diskon, Quick Cash, kalkulasi kembalian, '
                                'dan penyimpanan transaksi atomik akan diimplementasikan pada Tahap 11.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Ringkasan Pesanan Keranjang
                Text(
                  'Ringkasan Pesanan (${state.totalItems} item)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: state.lines.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final line = state.lines[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${line.qty}x',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (line.selectedAddons.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '+ ${line.selectedAddons.map((a) => a.name).join(', ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            RupiahFormatter.format(line.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Total Tagihan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan:',
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
                ),

                const SizedBox(height: 32),

                // Tombol Kembali
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Layar Kasir'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

