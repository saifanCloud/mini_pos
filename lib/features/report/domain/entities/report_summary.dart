import 'package:equatable/equatable.dart';

/// Ringkasan laporan penjualan untuk satu rentang waktu (F9 PRD).
class ReportSummary extends Equatable {
  final int totalRevenue;
  final int totalTransactions;
  final List<TransactionHistoryItem> transactions;

  const ReportSummary({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.transactions,
  });

  /// Kondisi belum ada transaksi sama sekali.
  bool get isEmpty => totalTransactions == 0;

  @override
  List<Object?> get props => [totalRevenue, totalTransactions, transactions];
}

/// Baris riwayat transaksi pada layar laporan (hanya dari snapshot, tanpa join master).
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
  List<Object?> get props => [id, cashierName, total, totalItems, createdAt];
}

