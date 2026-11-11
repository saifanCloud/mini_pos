import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/addon/domain/entities/addon.dart';
import 'package:mini_pos/features/cashier/domain/entities/cart.dart';
import 'package:mini_pos/features/cashier/domain/entities/cart_line.dart';
import 'package:mini_pos/features/cashier/domain/entities/discount.dart';
import 'package:mini_pos/features/cashier/domain/entities/transaction_entity.dart';
import 'package:mini_pos/features/cashier/domain/repositories/transaction_repository.dart';
import 'package:mini_pos/features/cashier/presentation/cubit/checkout_cubit.dart';
import 'package:mini_pos/features/cashier/presentation/cubit/checkout_state.dart';
import 'package:mini_pos/features/product/domain/entities/product.dart';

class MockTransactionRepository implements TransactionRepository {
  bool shouldFail = false;
  String failureMessage = 'Database error';
  int nextTransactionId = 101;

  Cart? lastCart;
  CheckoutTotals? lastTotals;
  int? lastPaid;
  int? lastChange;

  @override
  Future<int> saveTransaction({
    required Cart cart,
    required CheckoutTotals totals,
    required int paid,
    required int changeAmount,
  }) async {
    if (shouldFail) {
      throw Exception(failureMessage);
    }
    lastCart = cart;
    lastTotals = totals;
    lastPaid = paid;
    lastChange = changeAmount;
    return nextTransactionId++;
  }

  @override
  Future<TransactionEntity?> getTransactionById(int id) async {
    return null;
  }
}

void main() {
  group('CheckoutCubit & Quick Cash Tests (Tahap 11 & D3 PRD)', () {
    late MockTransactionRepository mockRepository;
    late CheckoutCubit checkoutCubit;

    const testProduct = Product(
      id: 1,
      name: 'Kopi Susu',
      price: 18000,
      stock: 10,
    );

    const testAddon = Addon(
      id: 1,
      name: 'Extra Shot',
      price: 4000,
      stock: 5,
    );

    final testCart = Cart(
      lines: const [
        CartLine(
          product: testProduct,
          selectedAddons: [testAddon],
          qty: 1,
        ),
      ],
    );

    setUp(() {
      mockRepository = MockTransactionRepository();
      checkoutCubit = CheckoutCubit(mockRepository);
    });

    tearDown(() {
      checkoutCubit.close();
    });

    test('State awal CheckoutCubit adalah initial', () {
      expect(checkoutCubit.state.status, CheckoutStatus.initial);
      expect(checkoutCubit.state.discountType, isNull);
      expect(checkoutCubit.state.discountValue, 0);
      expect(checkoutCubit.state.paidAmount, 0);
    });

    test('Quick Cash: rekomendasi pecahan di atas total tanpa duplikat', () {
      // Total 15.000 -> pembulatan 20.000, 50.000, 100.000
      final q1 = CheckoutCubit.getQuickCashSuggestions(15000);
      expect(q1, [20000, 50000, 100000]);

      // Total 37.000 -> pembulatan 40.000, 50.000, 100.000
      final q2 = CheckoutCubit.getQuickCashSuggestions(37000);
      expect(q2, [40000, 50000, 100000]);

      // Total 50.000 -> pembulatan 60.000, 100.000
      final q3 = CheckoutCubit.getQuickCashSuggestions(50000);
      expect(q3, [60000, 100000]);

      // Total 0 atau negatif -> kosong
      expect(CheckoutCubit.getQuickCashSuggestions(0), isEmpty);
      expect(CheckoutCubit.getQuickCashSuggestions(-5000), isEmpty);
    });

    test('setDiscount mengatur dan menghapus diskon', () {
      checkoutCubit.setDiscount(DiscountType.percent, 10);
      expect(checkoutCubit.state.discountType, DiscountType.percent);
      expect(checkoutCubit.state.discountValue, 10);

      checkoutCubit.setDiscount(DiscountType.fixed, 5000);
      expect(checkoutCubit.state.discountType, DiscountType.fixed);
      expect(checkoutCubit.state.discountValue, 5000);

      checkoutCubit.setDiscount(null, 0);
      expect(checkoutCubit.state.discountType, isNull);
      expect(checkoutCubit.state.discountValue, 0);
    });

    test('setPaidAmount mengubah nominal uang diterima', () {
      checkoutCubit.setPaidAmount(50000);
      expect(checkoutCubit.state.paidAmount, 50000);
    });

    test('processPayment menolak jika keranjang kosong', () async {
      const emptyCart = Cart();
      const totals = CheckoutTotals(subtotal: 0, total: 0);

      final success = await checkoutCubit.processPayment(
        cart: emptyCart,
        totals: totals,
        changeAmount: 0,
      );

      expect(success, isFalse);
      expect(checkoutCubit.state.status, CheckoutStatus.failure);
      expect(checkoutCubit.state.errorMessage, contains('kosong'));
    });

    test('processPayment menolak jika uang dibayarkan kurang dari total',
        () async {
      const totals = CheckoutTotals(subtotal: 22000, total: 22000);
      checkoutCubit.setPaidAmount(20000); // kurang 2.000

      final success = await checkoutCubit.processPayment(
        cart: testCart,
        totals: totals,
        changeAmount: -2000,
      );

      expect(success, isFalse);
      expect(checkoutCubit.state.status, CheckoutStatus.failure);
      expect(checkoutCubit.state.errorMessage, contains('kurang'));
    });

    test('processPayment sukses menyimpan transaksi dan mengembalikan txId',
        () async {
      const totals = CheckoutTotals(subtotal: 22000, total: 22000);
      checkoutCubit.setPaidAmount(50000);

      final success = await checkoutCubit.processPayment(
        cart: testCart,
        totals: totals,
        changeAmount: 28000,
      );

      expect(success, isTrue);
      expect(checkoutCubit.state.status, CheckoutStatus.success);
      expect(checkoutCubit.state.transactionId, 101);
      expect(mockRepository.lastPaid, 50000);
      expect(mockRepository.lastChange, 28000);
    });

    test('processPayment menangani kegagalan penyimpanan database', () async {
      mockRepository.shouldFail = true;
      mockRepository.failureMessage =
          'Stok produk Kopi Susu tidak mencukupi (sisa: 0)';

      const totals = CheckoutTotals(subtotal: 22000, total: 22000);
      checkoutCubit.setPaidAmount(50000);

      final success = await checkoutCubit.processPayment(
        cart: testCart,
        totals: totals,
        changeAmount: 28000,
      );

      expect(success, isFalse);
      expect(checkoutCubit.state.status, CheckoutStatus.failure);
      expect(checkoutCubit.state.errorMessage,
          contains('Stok produk Kopi Susu tidak mencukupi'));
    });

    test('processPayment sukses saat total Rp0 (diskon 100%) dengan paid Rp0',
        () async {
      const totals = CheckoutTotals(
        subtotal: 22000,
        discountType: DiscountType.percent,
        discountValue: 100,
        discountAmount: 22000,
        total: 0,
      );

      final success = await checkoutCubit.processPayment(
        cart: testCart,
        totals: totals,
        changeAmount: 0,
      );

      expect(success, isTrue);
      expect(checkoutCubit.state.status, CheckoutStatus.success);
      expect(mockRepository.lastTotals?.total, 0);
      expect(mockRepository.lastPaid, 0);
      expect(mockRepository.lastChange, 0);
    });

    test('reset mengembalikan state ke initial', () {
      checkoutCubit.setDiscount(DiscountType.percent, 10);
      checkoutCubit.setPaidAmount(50000);

      checkoutCubit.reset();
      expect(checkoutCubit.state.status, CheckoutStatus.initial);
      expect(checkoutCubit.state.discountType, isNull);
      expect(checkoutCubit.state.paidAmount, 0);
    });
  });
}

