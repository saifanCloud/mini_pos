import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/cashier/domain/entities/transaction_entity.dart';
import 'package:mini_pos/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:mini_pos/features/receipt/presentation/cubit/receipt_cubit.dart';
import 'package:mini_pos/features/receipt/presentation/cubit/receipt_state.dart';

class MockReceiptRepository implements ReceiptRepository {
  final Map<int, TransactionEntity> _transactions = {};

  void addTransaction(TransactionEntity tx) {
    if (tx.id != null) {
      _transactions[tx.id!] = tx;
    }
  }

  @override
  Future<TransactionEntity?> getReceipt(int transactionId) async {
    return _transactions[transactionId];
  }
}

void main() {
  group('ReceiptCubit Tests (Tahap 12 & F8 PRD)', () {
    late MockReceiptRepository mockRepository;
    late ReceiptCubit receiptCubit;

    const testTx = TransactionEntity(
      id: 1,
      cashierName: 'Budi Kasir',
      storeName: 'Kopi Kenangan Mantan',
      storeAddress: 'Jl. Merdeka No. 45',
      subtotal: 30000,
      discountType: 'percent',
      discountValue: 10,
      discountAmount: 3000,
      total: 27000,
      paid: 30000,
      changeAmount: 3000,
      createdAt: '2026-11-10T15:30:00.000',
      items: [
        TransactionItemEntity(
          id: 1,
          transactionId: 1,
          productName: 'Kopi Susu',
          unitPrice: 15000,
          qty: 2,
          addons: [
            TransactionItemAddonEntity(
              id: 1,
              transactionItemId: 1,
              addonName: 'Extra Shot',
              unitPrice: 3000,
              qty: 2,
            ),
          ],
        ),
      ],
    );

    setUp(() {
      mockRepository = MockReceiptRepository();
      receiptCubit = ReceiptCubit(mockRepository);
    });

    tearDown(() {
      receiptCubit.close();
    });

    test('State awal ReceiptCubit adalah ReceiptInitial', () {
      expect(receiptCubit.state, isA<ReceiptInitial>());
    });

    test('loadReceipt sukses memuat data struk transaksi snapshot', () async {
      mockRepository.addTransaction(testTx);

      expectLater(
        receiptCubit.stream,
        emitsInOrder([
          isA<ReceiptLoading>(),
          isA<ReceiptLoaded>().having(
            (s) => s.transaction.storeName,
            'storeName',
            'Kopi Kenangan Mantan',
          ),
        ]),
      );

      await receiptCubit.loadReceipt(1);
    });

    test('loadReceipt mengembalikan ReceiptError jika ID tidak ditemukan',
        () async {
      expectLater(
        receiptCubit.stream,
        emitsInOrder([
          isA<ReceiptLoading>(),
          isA<ReceiptError>().having(
            (s) => s.message,
            'message',
            contains('tidak ditemukan'),
          ),
        ]),
      );

      await receiptCubit.loadReceipt(999);
    });
  });
}

