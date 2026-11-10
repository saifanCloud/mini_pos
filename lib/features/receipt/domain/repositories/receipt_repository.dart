import '../../../cashier/domain/entities/transaction_entity.dart';

/// Kontrak repository untuk membaca data struk digital (F8 & B2 PRD).
/// Membaca hanya dari tabel transaksi dan snapshot riwayat.
abstract class ReceiptRepository {
  /// Mengambil data transaksi lengkap berdasarkan [transactionId].
  /// Mengembalikan [TransactionEntity] jika ditemukan, atau null jika tidak ada.
  Future<TransactionEntity?> getReceipt(int transactionId);
}
