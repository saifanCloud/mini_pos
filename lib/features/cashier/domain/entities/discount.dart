import 'package:equatable/equatable.dart';

/// Jenis potongan diskon yang didukung aplikasi.
enum DiscountType {
  /// Diskon persentase (0 sampai 100 persen).
  percent,

  /// Diskon nominal tetap (Rupiah).
  fixed,
}

/// Hasil kalkulasi total pembayaran pada transaksi kasir.
class CheckoutTotals extends Equatable {
  final int subtotal;
  final DiscountType? discountType;
  final int discountValue;
  final int discountAmount;
  final int total;

  const CheckoutTotals({
    required this.subtotal,
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
    required this.total,
  });

  bool get hasDiscount => discountAmount > 0;

  @override
  List<Object?> get props => [
        subtotal,
        discountType,
        discountValue,
        discountAmount,
        total,
      ];
}

