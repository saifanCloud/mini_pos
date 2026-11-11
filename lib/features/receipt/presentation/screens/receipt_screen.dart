import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../cashier/domain/entities/transaction_entity.dart';
import '../../../cashier/presentation/cubit/cashier_cubit.dart';
import '../cubit/receipt_cubit.dart';
import '../cubit/receipt_state.dart';

/// Layar Struk Digital Penjualan (F8, B2 PRD & Tahap B).
/// Menampilkan struk bergaya kertas kasir berlatar putih dengan font monospasi sistem,
/// garis putus-putus pemisah, rata kiri-kanan rapi, dan tombol Transaksi Baru menonjol.
class ReceiptScreen extends StatelessWidget {
  final int transactionId;

  const ReceiptScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
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
                return const LoadingView(message: 'Memuat data struk...');
              }

              if (state is ReceiptError) {
                return ErrorView(
                  message: state.message,
                  retryButtonText: 'Kembali ke Kasir',
                  onRetry: () => _returnToCashier(context),
                );
              }

              final tx = (state as ReceiptLoaded).transaction;

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Banner Sukses di atas struk (Tahap B)
                      _buildSuccessBanner(),

                      const SizedBox(height: AppSpacing.md),

                      // Kertas Struk Fisik Monospaced (Tahap B)
                      _buildReceiptPaper(tx),

                      const SizedBox(height: AppSpacing.xl),

                      // Tombol Transaksi Baru yang Menonjol (Tinggi 52 dp)
                      PrimaryButton(
                        height: 52,
                        icon: Icons.add_shopping_cart_rounded,
                        label: 'Mulai Transaksi Baru',
                        onPressed: () => _returnToCashier(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
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

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.green.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade700,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Transaksi Berhasil Disimpan',
            style: TextStyle(
              color: Colors.green.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPaper(TransactionEntity tx) {
    final dateTime = DateTime.tryParse(tx.createdAt)?.toLocal();
    final formattedDate = dateTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
        : tx.createdAt;

    const monoStyle = TextStyle(
      fontFamily: 'monospace',
      color: Colors.black87,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Toko (F10 & B2 PRD)
          Center(
            child: Text(
              tx.storeName.toUpperCase(),
              style: monoStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (tx.storeAddress != null && tx.storeAddress!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                tx.storeAddress!,
                style: monoStyle.copyWith(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          _buildDashedDivider(),
          const SizedBox(height: AppSpacing.md),

          // Metadata Transaksi
          _buildMetaRow('No. Transaksi', '#${tx.id ?? "-"}', monoStyle),
          const SizedBox(height: 3),
          _buildMetaRow('Kasir', tx.cashierName, monoStyle),
          const SizedBox(height: 3),
          _buildMetaRow('Waktu', formattedDate, monoStyle),

          const SizedBox(height: AppSpacing.md),
          _buildDashedDivider(),
          const SizedBox(height: AppSpacing.md),

          // Daftar Item & Add-on (B2 Snapshot)
          ...tx.items.map((item) => _buildItemBlock(item, monoStyle)),

          const SizedBox(height: AppSpacing.sm),
          _buildDashedDivider(),
          const SizedBox(height: AppSpacing.md),

          // Rincian Pembayaran
          _buildSummaryRow(
            'Subtotal',
            RupiahFormatter.format(tx.subtotal),
            monoStyle,
          ),
          if (tx.discountAmount > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'Diskon (${tx.discountType == "percent" ? "${tx.discountValue}%" : "Nominal"})',
              '- ${RupiahFormatter.format(tx.discountAmount)}',
              monoStyle.copyWith(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 6),
          _buildSummaryRow(
            'TOTAL',
            RupiahFormatter.format(tx.total),
            monoStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Tunai',
            RupiahFormatter.format(tx.paid),
            monoStyle,
          ),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Kembalian',
            RupiahFormatter.format(tx.changeAmount),
            monoStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          _buildDashedDivider(),
          const SizedBox(height: AppSpacing.lg),

          // Ucapan Penutup
          Center(
            child: Text(
              'Terima kasih atas kunjungan Anda!',
              style: monoStyle.copyWith(
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

  Widget _buildItemBlock(TransactionItemEntity item, TextStyle monoStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                  style: monoStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${item.qty}x',
                style: monoStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 80,
                child: Text(
                  RupiahFormatter.format(item.subtotal),
                  style: monoStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                      style: monoStyle.copyWith(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Text(
                    '${addon.qty}x ${RupiahFormatter.format(addon.unitPrice)}',
                    style: monoStyle.copyWith(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 80,
                    child: Text(
                      RupiahFormatter.format(addon.subtotal),
                      style: monoStyle.copyWith(
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

  Widget _buildMetaRow(String label, String value, TextStyle monoStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: monoStyle.copyWith(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: monoStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, TextStyle style) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
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
