import '../entities/cart.dart';
import '../entities/discount.dart';
import '../entities/transaction_entity.dart';

/// Kontrak repository untuk transaksi kasir dan pembayaran.
abstract class TransactionRepository {
  /// Menyimpan transaksi pembayaran secara atomik dalam satu database transaction (B5 PRD).
  /// Mengembalikan ID transaksi yang berhasil dibuat.
  Future<int> saveTransaction({
    required Cart cart,
    required CheckoutTotals totals,
    required int paid,
    required int changeAmount,
  });

  /// Mengambil rincian transaksi lengkap beserta snapshot item dan add-on-nya.
  Future<TransactionEntity?> getTransactionById(int id);
}

