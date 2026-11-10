import 'package:equatable/equatable.dart';
import '../../../cashier/domain/entities/transaction_entity.dart';

abstract class ReceiptState extends Equatable {
  const ReceiptState();

  @override
  List<Object?> get props => [];
}

class ReceiptInitial extends ReceiptState {
  const ReceiptInitial();
}

class ReceiptLoading extends ReceiptState {
  const ReceiptLoading();
}

class ReceiptLoaded extends ReceiptState {
  final TransactionEntity transaction;

  const ReceiptLoaded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class ReceiptError extends ReceiptState {
  final String message;

  const ReceiptError(this.message);

  @override
  List<Object?> get props => [message];
}
