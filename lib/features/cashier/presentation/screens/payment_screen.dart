import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/price_text.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/discount.dart';
import '../../domain/usecases/cart_logic.dart';
import '../../../receipt/presentation/screens/receipt_screen.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';

/// Layar Pembayaran Kasir (F7, B2, B4, B5, D3 PRD & Tahap B).
/// - Ringkasan pesanan keranjang terstruktur
/// - Input diskon ringkas (persen atau nominal) divalidasi dengan proteksi B4
/// - Total tagihan sangat menonjol
/// - Input uang diterima dengan keyboard angka
/// - Quick Cash chip besar (Uang Pas & pembulatan pecahan)
/// - Hitungan kembalian instan dengan warna kontras
/// - Tombol Konfirmasi Pembayaran besar selalu terlihat di bawah dengan indikator alasan jelas
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();

  DiscountType? _selectedDiscountType;
  int _discountValue = 0;
  int _paidAmount = 0;

  @override
  void dispose() {
    _discountController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _onDiscountTypeChanged(DiscountType? type) {
    setState(() {
      _selectedDiscountType = type;
      if (type == null) {
        _discountController.clear();
        _discountValue = 0;
      }
    });
  }

  void _onDiscountValueChanged(String value) {
    final parsed = int.tryParse(value) ?? 0;
    setState(() {
      _discountValue = parsed;
    });
  }

  void _onPaidAmountChanged(String value) {
    final parsed = int.tryParse(value) ?? 0;
    setState(() {
      _paidAmount = parsed;
    });
    context.read<CheckoutCubit>().setPaidAmount(parsed);
  }

  void _applyQuickCash(int amount) {
    setState(() {
      _paidAmount = amount;
      _paidController.text = amount.toString();
    });
    context.read<CheckoutCubit>().setPaidAmount(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, checkoutState) {
        if (checkoutState.status == CheckoutStatus.failure) {
          AppSnackBar.showError(
            context,
            checkoutState.errorMessage ?? 'Pembayaran gagal disimpan',
          );
        }
      },
      builder: (context, checkoutState) {
        return BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final cart = cartState.cart;
            final subtotal = cart.subtotal;

            // Validasi diskon memakai fungsi murni CartLogic tahap 9 (B4 PRD)
            final discountError = CartLogic.validateDiscount(
              subtotal,
              discountType: _selectedDiscountType,
              discountValue: _discountValue,
            );

            // Hitung total dan potongan diskon dengan proteksi clamp (B4 PRD)
            final totals = CartLogic.calculateTotals(
              subtotal,
              discountType: discountError == null ? _selectedDiscountType : null,
              discountValue: discountError == null ? _discountValue : 0,
            );

            final changeAmount = _paidAmount - totals.total;
            final isPaidSufficient = _paidAmount >= totals.total && totals.total > 0;
            final canConfirm = cart.isNotEmpty &&
                isPaidSufficient &&
                discountError == null &&
                checkoutState.status != CheckoutStatus.submitting;

            // Daftar opsi pembulatan Quick Cash (D3 PRD)
            final quickCashOptions =
                CheckoutCubit.getQuickCashSuggestions(totals.total);

            // Teks status alasan tombol nonaktif (UX Ergonomis)
            String buttonLabel;
            if (checkoutState.status == CheckoutStatus.submitting) {
              buttonLabel = 'Memproses Transaksi...';
            } else if (cart.isEmpty) {
              buttonLabel = 'Keranjang Belanja Kosong';
            } else if (discountError != null) {
              buttonLabel = 'Periksa Kembali Diskon';
            } else if (_paidAmount == 0) {
              buttonLabel = 'Masukkan Uang Diterima';
            } else if (!isPaidSufficient) {
              buttonLabel = 'Uang Masih Kurang (${RupiahFormatter.format(totals.total - _paidAmount)})';
            } else {
              buttonLabel = 'Konfirmasi Bayar (${RupiahFormatter.format(totals.total)})';
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Pembayaran Tunai'),
                centerTitle: true,
              ),
              // Tombol Konfirmasi selalu terlihat di bawah dan melayang (PRD Bagian 12)
              bottomNavigationBar: cart.isEmpty
                  ? null
                  : SafeArea(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: canConfirm
                              ? () => _handleConfirmPayment(
                                    context: context,
                                    cart: cart,
                                    totals: totals,
                                    changeAmount: changeAmount,
                                  )
                              : null,
                          icon: checkoutState.status == CheckoutStatus.submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
              body: cart.isEmpty
                  ? EmptyState(
                      icon: Icons.remove_shopping_cart_outlined,
                      title: 'Keranjang Belanja Kosong',
                      description:
                          'Tidak ada produk yang siap dibayar. Kembali ke kasir untuk menambah item.',
                      buttonText: 'Kembali ke Kasir',
                      onButtonPressed: () => Navigator.pop(context),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Ringkasan Pesanan (SectionCard)
                          _buildCartSummarySection(cartState, theme),

                          const SizedBox(height: AppSpacing.lg),

                          // 2. Bagian Input Diskon (F7 & B4 PRD)
                          _buildDiscountSection(
                            theme: theme,
                            subtotal: subtotal,
                            discountError: discountError,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // 3. Ringkasan Biaya (Subtotal, Diskon, Total Menonjol)
                          _buildTotalsSection(totals, theme),

                          const SizedBox(height: AppSpacing.lg),

                          // 4. Pembayaran Tunai & Quick Cash (D3 PRD)
                          _buildCashPaymentSection(
                            theme: theme,
                            total: totals.total,
                            changeAmount: changeAmount,
                            isPaidSufficient: isPaidSufficient,
                            quickCashOptions: quickCashOptions,
                          ),

                          // Jarak penutup agar konten paling bawah nyaman dibaca
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartSummarySection(CartState cartState, ThemeData theme) {
    return SectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Ringkasan Pesanan (${cartState.totalItems} item)',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cartState.lines.length,
        separatorBuilder: (_, _) => const Divider(height: 14),
        itemBuilder: (context, index) {
          final line = cartState.lines[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '${line.qty}x',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (line.selectedAddons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+ ${line.selectedAddons.map((a) => a.name).join(", ")}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PriceText(
                line.subtotal,
                size: PriceSize.small,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiscountSection({
    required ThemeData theme,
    required int subtotal,
    required String? discountError,
  }) {
    return SectionCard(
      icon: Icons.discount_outlined,
      title: 'Diskon Belanja (Opsional)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Button Tipe Diskon
          SegmentedButton<DiscountType?>(
            segments: const [
              ButtonSegment<DiscountType?>(
                value: null,
                label: Text('Tanpa Diskon'),
              ),
              ButtonSegment<DiscountType?>(
                value: DiscountType.percent,
                label: Text('Persen (%)'),
              ),
              ButtonSegment<DiscountType?>(
                value: DiscountType.fixed,
                label: Text('Nominal (Rp)'),
              ),
            ],
            selected: {_selectedDiscountType},
            onSelectionChanged: (selected) {
              _onDiscountTypeChanged(selected.first);
            },
          ),

          if (_selectedDiscountType != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: _selectedDiscountType == DiscountType.percent
                    ? 'Nilai Diskon Persen (0 - 100)'
                    : 'Nilai Diskon Nominal (Rp)',
                prefixText:
                    _selectedDiscountType == DiscountType.fixed ? 'Rp ' : null,
                suffixText:
                    _selectedDiscountType == DiscountType.percent ? '%' : null,
                errorText: discountError,
              ),
              onChanged: _onDiscountValueChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalsSection(CheckoutTotals totals, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          _buildRowItem(
            'Subtotal',
            PriceText(totals.subtotal, size: PriceSize.small, color: theme.colorScheme.onSurface),
          ),
          if (totals.hasDiscount) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Potongan Diskon (${totals.discountType == DiscountType.percent ? "${totals.discountValue}%" : "Nominal"})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  '- ${RupiahFormatter.format(totals.discountAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tagihan:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PriceText(
                totals.total,
                size: PriceSize.large,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashPaymentSection({
    required ThemeData theme,
    required int total,
    required int changeAmount,
    required bool isPaidSufficient,
    required List<int> quickCashOptions,
  }) {
    return SectionCard(
      icon: Icons.payments_outlined,
      title: 'Pembayaran Tunai',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Nominal Uang Diterima
          TextField(
            controller: _paidController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              labelText: 'Uang Diterima dari Pelanggan',
              prefixText: 'Rp ',
              hintText: '0',
            ),
            onChanged: _onPaidAmountChanged,
          ),

          const SizedBox(height: AppSpacing.md),

          // Pilihan Quick Cash (D3 PRD)
          Text(
            'Pilihan Cepat (Quick Cash):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // Tombol Uang Pas
              ActionChip(
                avatar: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text(
                  'Uang Pas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                onPressed: () => _applyQuickCash(total),
              ),
              // Tombol Pecahan Pembulatan
              ...quickCashOptions.map((opt) {
                return ActionChip(
                  label: Text(
                    RupiahFormatter.format(opt),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onPressed: () => _applyQuickCash(opt),
                );
              }),
            ],
          ),

          const Divider(height: AppSpacing.xl),

          // Tampilan Kembalian / Kekurangan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPaidSufficient ? 'Kembalian:' : 'Uang Masih Kurang:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isPaidSufficient
                      ? Colors.green.shade800
                      : theme.colorScheme.error,
                ),
              ),
              PriceText(
                isPaidSufficient ? changeAmount : (total - _paidAmount),
                size: PriceSize.large,
                color: isPaidSufficient
                    ? Colors.green.shade800
                    : theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, Widget trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        trailing,
      ],
    );
  }

  Future<void> _handleConfirmPayment({
    required BuildContext context,
    required cart,
    required CheckoutTotals totals,
    required int changeAmount,
  }) async {
    final checkoutCubit = context.read<CheckoutCubit>();
    final cartCubit = context.read<CartCubit>();

    final success = await checkoutCubit.processPayment(
      cart: cart,
      totals: totals,
      changeAmount: changeAmount,
    );

    if (success && context.mounted) {
      final txId = checkoutCubit.state.transactionId ?? 0;

      // 1. Kosongkan keranjang belanja
      cartCubit.clearCart();

      // 2. Arahkan ke halaman Struk Digital (Tahap 12)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            transactionId: txId,
          ),
        ),
      );
    }
  }
}
