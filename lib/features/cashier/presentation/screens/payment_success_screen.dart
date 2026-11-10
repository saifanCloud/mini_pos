import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../cubit/cashier_cubit.dart';

/// Halaman Transaksi Berhasil (Tahap 11).
/// Menampilkan konfirmasi keberhasilan transaksi beserta ID transaksi.
/// Fitur cetak dan preview struk digital lengkap akan diimplementasikan pada Tahap 12.
class PaymentSuccessScreen extends StatelessWidget {
  final int transactionId;
  final int total;
  final int paid;
  final int changeAmount;

  const PaymentSuccessScreen({
    super.key,
    required this.transactionId,
    required this.total,
    required this.paid,
    required this.changeAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _returnToCashier(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran Berhasil'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Ikon Sukses
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.shade400,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.green.shade700,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Transaksi Berhasil!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'ID Transaksi: #$transactionId',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Ringkasan Pembayaran
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _buildRow(
                          'Total Belanja',
                          RupiahFormatter.format(total),
                          isBold: true,
                          theme: theme,
                        ),
                        const Divider(height: 20),
                        _buildRow(
                          'Uang Diterima',
                          RupiahFormatter.format(paid),
                          theme: theme,
                        ),
                        const SizedBox(height: 10),
                        _buildRow(
                          'Kembalian',
                          RupiahFormatter.format(changeAmount),
                          isBold: true,
                          valueColor: Colors.green.shade800,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Informasi Tahap 12
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Struk digital dan riwayat transaksi akan tersedia pada Tahap 12.',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Tombol Transaksi Baru
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _returnToCashier(context),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text(
                    'Transaksi Baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _returnToCashier(BuildContext context) {
    // Muat ulang katalog produk kasir agar pengurangan stok langsung terlihat
    context.read<CashierCubit>().loadData();
    // Kembali ke layar kasir utama
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isBold ? theme.colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}

