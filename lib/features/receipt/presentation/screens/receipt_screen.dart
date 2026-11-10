import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../cashier/domain/entities/transaction_entity.dart';
import '../../../cashier/presentation/cubit/cashier_cubit.dart';
import '../cubit/receipt_cubit.dart';
import '../cubit/receipt_state.dart';

/// Layar Struk Digital Penjualan (F8 & B2 PRD).
/// Menampilkan struk bergaya kertas kasir yang bersumber murni dari data snapshot.
class ReceiptScreen extends StatelessWidget {
  final int transactionId;

  const ReceiptScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<ReceiptCubit>(
      create: (_) => sl<ReceiptCubit>()..loadReceipt(transactionId),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _returnToCashier(context);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Struk Digital'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: BlocBuilder<ReceiptCubit, ReceiptState>(
            builder: (context, state) {
              if (state is ReceiptLoading || state is ReceiptInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ReceiptError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _returnToCashier(context),
                          child: const Text('Kembali ke Kasir'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final tx = (state as ReceiptLoaded).transaction;

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Kertas Struk
                      _buildReceiptPaper(tx, theme),

                      const SizedBox(height: 24),

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
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _returnToCashier(BuildContext context) {
    // Muat ulang katalog produk kasir agar sisa stok langsung terbarukan
    context.read<CashierCubit>().loadData();
    // Kembali ke layar kasir utama
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildReceiptPaper(TransactionEntity tx, ThemeData theme) {
    final dateTime = DateTime.tryParse(tx.createdAt)?.toLocal();
    final formattedDate = dateTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
        : tx.createdAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Toko (F10 & B2 PRD)
          Center(
            child: Text(
              tx.storeName.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (tx.storeAddress != null && tx.storeAddress!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                tx.storeAddress!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // Metadata Transaksi
          _buildMetaRow('No. Transaksi', '#${tx.id ?? "-"}'),
          const SizedBox(height: 4),
          _buildMetaRow('Kasir', tx.cashierName),
          const SizedBox(height: 4),
          _buildMetaRow('Waktu', formattedDate),

          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // Daftar Item & Add-on (B2 Snapshot)
          ...tx.items.map((item) => _buildItemBlock(item)),

          const SizedBox(height: 8),
          _buildDashedDivider(),
          const SizedBox(height: 12),

          // Rincian Pembayaran
          _buildSummaryRow('Subtotal', RupiahFormatter.format(tx.subtotal)),
          if (tx.discountAmount > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'Diskon (${tx.discountType == "percent" ? "${tx.discountValue}%" : "Nominal"})',
              '- ${RupiahFormatter.format(tx.discountAmount)}',
              textColor: Colors.red.shade700,
            ),
          ],
          const SizedBox(height: 6),
          _buildSummaryRow(
            'TOTAL',
            RupiahFormatter.format(tx.total),
            isBold: true,
            fontSize: 16,
          ),
          const SizedBox(height: 6),
          _buildSummaryRow('Tunai', RupiahFormatter.format(tx.paid)),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Kembalian',
            RupiahFormatter.format(tx.changeAmount),
            isBold: true,
          ),

          const SizedBox(height: 16),
          _buildDashedDivider(),
          const SizedBox(height: 16),

          // Ucapan Penutup
          const Center(
            child: Text(
              'Terima kasih atas kunjungan Anda!',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBlock(TransactionItemEntity item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Baris Produk Utama
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.qty}x',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 75,
                child: Text(
                  RupiahFormatter.format(item.subtotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          // Baris Add-on (jika ada)
          ...item.addons.map((addon) {
            return Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '+ ${addon.addonName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Text(
                    '${addon.qty}x ${RupiahFormatter.format(addon.unitPrice)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 75,
                    child: Text(
                      RupiahFormatter.format(addon.subtotal),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
              ),
            );
          }),
        );
      },
    );
  }
}
