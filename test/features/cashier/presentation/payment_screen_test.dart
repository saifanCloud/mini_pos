import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/cashier/domain/entities/cart.dart';
import 'package:mini_pos/features/cashier/domain/entities/discount.dart';
import 'package:mini_pos/features/cashier/domain/entities/transaction_entity.dart';
import 'package:mini_pos/features/cashier/domain/repositories/transaction_repository.dart';
import 'package:mini_pos/features/cashier/presentation/cubit/cart_cubit.dart';
import 'package:mini_pos/features/cashier/presentation/cubit/checkout_cubit.dart';
import 'package:mini_pos/features/cashier/presentation/screens/payment_screen.dart';
import 'package:mini_pos/features/product/domain/entities/product.dart';

class _FakeTransactionRepository implements TransactionRepository {
  @override
  Future<int> saveTransaction({
    required Cart cart,
    required CheckoutTotals totals,
    required int paid,
    required int changeAmount,
  }) async {
    return 1;
  }

  @override
  Future<TransactionEntity?> getTransactionById(int id) async => null;
}

void main() {
  testWidgets(
    'PaymentScreen mengizinkan konfirmasi bayar Rp0 saat diskon 100%',
    (tester) async {
      const product = Product(
        id: 1,
        name: 'Kopi Susu',
        price: 15000,
        stock: 5,
      );

      final cartCubit = CartCubit()..addToCart(product, []);
      final checkoutCubit = CheckoutCubit(_FakeTransactionRepository());
      addTearDown(() async {
        await cartCubit.close();
        await checkoutCubit.close();
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
          ],
          child: const MaterialApp(
            home: PaymentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sebelum diskon & sebelum input uang: tombol nonaktif dengan label instruksi
      expect(find.text('Masukkan Uang Diterima'), findsOneWidget);
      FilledButton confirmButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(confirmButton.onPressed, isNull);

      // Pilih diskon Persen (%) dan masukkan 100%
      await tester.tap(find.text('Persen (%)'));
      await tester.pumpAndSettle();

      final discountField = find.widgetWithText(
        TextField,
        'Nilai Diskon Persen (0 - 100)',
      );
      await tester.enterText(discountField, '100');
      await tester.pumpAndSettle();

      // Total menjadi Rp0, tombol konfirmasi harus aktif walau uang diterima Rp0
      expect(find.text('Konfirmasi Bayar (Rp0)'), findsOneWidget);
      expect(find.text('Kembalian:'), findsOneWidget);
      confirmButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(confirmButton.onPressed, isNotNull);
    },
  );
}

