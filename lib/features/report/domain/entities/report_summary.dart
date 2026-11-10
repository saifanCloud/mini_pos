import 'package:equatable/equatable.dart';

/// Entity ringkasan laporan penjualan dan omzet (F9 PRD).
class ReportSummary extends Equatable {
  final int totalRevenue; // total omzet dalam rupiah
  final int totalTransactions; // jumlah transaksi sukses
  final List<TransactionHistoryItem> transactions; // daftar riwayat terbaru di atas

  const ReportSummary({
    this.totalRevenue = 0,
    this.totalTransactions = 0,
    this.transactions = const [],
  });

  bool get isEmpty => totalTransactions == 0;
  bool get isNotEmpty => totalTransactions > 0;

  @override
  List<Object?> get props => [
        totalRevenue,
        totalTransactions,
        transactions,
      ];
}

/// Entity item riwayat transaksi untuk daftar laporan.
class TransactionHistoryItem extends Equatable {
  final int id;
  final String cashierName;
  final int total;
  final int totalItems;
  final String createdAt; // ISO 8601 string

  const TransactionHistoryItem({
    required this.id,
    required this.cashierName,
    required this.total,
    required this.totalItems,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        cashierName,
        total,
        totalItems,
        createdAt,
      ];
}

