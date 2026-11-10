import 'package:flutter/material.dart';
import '../../../receipt/presentation/screens/receipt_screen.dart';

/// Halaman pengganti sementara Tahap 11 yang telah dialihkan ke [ReceiptScreen] di Tahap 12.
@Deprecated('Gunakan ReceiptScreen di Tahap 12')
class PaymentSuccessScreen extends StatelessWidget {
  final int transactionId;
  final int total;
  final int paid;
  final int changeAmount;

  const PaymentSuccessScreen({
    super.key,
    required this.transactionId,
    required this.total,
    required this.paid,
    required this.changeAmount,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiptScreen(transactionId: transactionId);
  }
}
