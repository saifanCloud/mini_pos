import 'package:equatable/equatable.dart';

/// Entity transaksi penjualan (snapshot) — layer domain murni Dart.
/// Sesuai B2 PRD: data nama produk, harga, kasir, dan toko disalin agar
/// riwayat tetap konsisten meskipun data master berubah atau dihapus.
class TransactionEntity extends Equatable {
  final int? id;
  final int? cashierId;
  final String cashierName;
  final String storeName;
  final String? storeAddress;
  final int subtotal;
  final String? discountType; // 'percent' atau 'fixed'
  final int discountValue;
  final int discountAmount;
  final int total;
  final int paid;
  final int changeAmount;
  final String createdAt; // waktu lokal format ISO 8601
  final List<TransactionItemEntity> items;

  const TransactionEntity({
    this.id,
    this.cashierId,
    required this.cashierName,
    required this.storeName,
    this.storeAddress,
    required this.subtotal,
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
    required this.total,
    required this.paid,
    required this.changeAmount,
    required this.createdAt,
    this.items = const [],
  });

  @override
  List<Object?> get props => [
        id,
        cashierId,
        cashierName,
        storeName,
        storeAddress,
        subtotal,
        discountType,
        discountValue,
        discountAmount,
        total,
        paid,
        changeAmount,
        createdAt,
        items,
      ];
}

/// Entity item dalam transaksi (snapshot).
class TransactionItemEntity extends Equatable {
  final int? id;
  final int? transactionId;
  final int? productId;
  final String productName;
  final int unitPrice;
  final int qty;
  final List<TransactionItemAddonEntity> addons;

  const TransactionItemEntity({
    this.id,
    this.transactionId,
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.qty,
    this.addons = const [],
  });

  int get subtotal => unitPrice * qty;

  @override
  List<Object?> get props => [
        id,
        transactionId,
        productId,
        productName,
        unitPrice,
        qty,
        addons,
      ];
}

/// Entity add-on terpilih untuk suatu item transaksi (snapshot).
class TransactionItemAddonEntity extends Equatable {
  final int? id;
  final int? transactionItemId;
  final int? addonId;
  final String addonName;
  final int unitPrice;
  final int qty;

  const TransactionItemAddonEntity({
    this.id,
    this.transactionItemId,
    this.addonId,
    required this.addonName,
    required this.unitPrice,
    required this.qty,
  });

  int get subtotal => unitPrice * qty;

  @override
  List<Object?> get props => [
        id,
        transactionItemId,
        addonId,
        addonName,
        unitPrice,
        qty,
      ];
}

