import 'package:equatable/equatable.dart';
import '../../domain/entities/discount.dart';

enum CheckoutStatus { initial, submitting, success, failure }

/// State untuk proses pembayaran (Tahap 11).
class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final DiscountType? discountType;
  final int discountValue;
  final int paidAmount;
  final String? errorMessage;
  final int? transactionId;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.discountType,
    this.discountValue = 0,
    this.paidAmount = 0,
    this.errorMessage,
    this.transactionId,
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    DiscountType? discountType,
    bool clearDiscountType = false,
    int? discountValue,
    int? paidAmount,
    String? errorMessage,
    int? transactionId,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      discountType: clearDiscountType
          ? null
          : (discountType ?? this.discountType),
      discountValue: discountValue ?? this.discountValue,
      paidAmount: paidAmount ?? this.paidAmount,
      errorMessage: errorMessage,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        discountType,
        discountValue,
        paidAmount,
        errorMessage,
        transactionId,
      ];
}

