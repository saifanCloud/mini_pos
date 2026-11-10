import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/rupiah_formatter.dart';
import '../../domain/entities/discount.dart';
import '../../domain/usecases/cart_logic.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import 'payment_success_screen.dart';

/// Layar Pembayaran Kasir (F7, B2, B4, B5, D3 PRD).
/// - Ringkasan pesanan keranjang
/// - Input diskon (persen atau nominal) divalidasi dengan proteksi B4
/// - Quick Cash tombol Uang Pas dan pembulatan pecahan di atas total
/// - Hitungan kembalian instan
/// - Konfirmasi pembayaran atomik
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
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(checkoutState.errorMessage ?? 'Pembayaran gagal'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
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

            return Scaffold(
              appBar: AppBar(
                title: const Text('Pembayaran'),
                centerTitle: true,
              ),
              body: cart.isEmpty
                  ? const Center(
                      child: Text('Keranjang belanja kosong'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Ringkasan Pesanan
                          _buildCartSummaryCard(cartState, theme),

                          const SizedBox(height: 16),

                          // 2. Bagian Input Diskon (F7 & B4 PRD)
                          _buildDiscountCard(
                            theme: theme,
                            subtotal: subtotal,
                            discountError: discountError,
                          ),

                          const SizedBox(height: 16),

                          // 3. Ringkasan Biaya (Subtotal, Diskon, Total)
                          _buildTotalsCard(totals, theme),

                          const SizedBox(height: 16),

                          // 4. Pembayaran Tunai & Quick Cash (D3 PRD)
                          _buildCashPaymentCard(
                            theme: theme,
                            total: totals.total,
                            changeAmount: changeAmount,
                            isPaidSufficient: isPaidSufficient,
                            quickCashOptions: quickCashOptions,
                          ),

                          const SizedBox(height: 24),

                          // 5. Tombol Konfirmasi Pembayaran
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                            icon: checkoutState.status ==
                                    CheckoutStatus.submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              checkoutState.status ==
                                      CheckoutStatus.submitting
                                  ? 'Memproses Transaksi...'
                                  : 'Konfirmasi Pembayaran (${RupiahFormatter.format(totals.total)})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartSummaryCard(CartState cartState, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ringkasan Pesanan (${cartState.totalItems} item)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartState.lines.length,
              separatorBuilder: (_, _) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final line = cartState.lines[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${line.qty}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (line.selectedAddons.isNotEmpty)
                            Text(
                              '+ ${line.selectedAddons.map((a) => a.name).join(", ")}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      RupiahFormatter.format(line.subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard({
    required ThemeData theme,
    required int subtotal,
    required String? discountError,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.discount_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Diskon (Opsional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
              const SizedBox(height: 12),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onChanged: _onDiscountValueChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(CheckoutTotals totals, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildRowItem('Subtotal', RupiahFormatter.format(totals.subtotal)),
          if (totals.hasDiscount) ...[
            const SizedBox(height: 6),
            _buildRowItem(
              'Diskon (${totals.discountType == DiscountType.percent ? "${totals.discountValue}%" : "Nominal"})',
              '- ${RupiahFormatter.format(totals.discountAmount)}',
              valueColor: Colors.red.shade700,
            ),
          ],
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tagihan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                RupiahFormatter.format(totals.total),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashPaymentCard({
    required ThemeData theme,
    required int total,
    required int changeAmount,
    required bool isPaidSufficient,
    required List<int> quickCashOptions,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Uang Diterima (Tunai)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Input Nominal Uang Diterima
            TextField(
              controller: _paidController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              onChanged: _onPaidAmountChanged,
            ),

            const SizedBox(height: 12),

            // Tombol Quick Cash (D3 PRD)
            const Text(
              'Quick Cash:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Tombol Uang Pas
                ActionChip(
                  avatar: const Icon(Icons.check, size: 16),
                  label: const Text('Uang Pas'),
                  onPressed: () => _applyQuickCash(total),
                ),
                // Tombol Pembulatan
                ...quickCashOptions.map((opt) {
                  return ActionChip(
                    label: Text(RupiahFormatter.format(opt)),
                    onPressed: () => _applyQuickCash(opt),
                  );
                }),
              ],
            ),

            const Divider(height: 22),

            // Kembalian / Status Pembayaran
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
                Text(
                  isPaidSufficient
                      ? RupiahFormatter.format(changeAmount)
                      : RupiahFormatter.format(total - _paidAmount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPaidSufficient
                        ? Colors.green.shade800
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
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

      // 2. Arahkan ke halaman Sukses Pembayaran
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            transactionId: txId,
            total: totals.total,
            paid: _paidAmount,
            changeAmount: changeAmount,
          ),
        ),
      );
    }
  }
}

