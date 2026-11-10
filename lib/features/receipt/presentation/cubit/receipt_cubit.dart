import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/receipt_repository.dart';
import 'receipt_state.dart';

/// Cubit untuk memuat data struk transaksi digital (F8 PRD).
class ReceiptCubit extends Cubit<ReceiptState> {
  final ReceiptRepository _receiptRepository;

  ReceiptCubit(this._receiptRepository) : super(const ReceiptInitial());

  /// Memuat rincian transaksi berdasarkan [transactionId].
  Future<void> loadReceipt(int transactionId) async {
    try {
      emit(const ReceiptLoading());
      final transaction = await _receiptRepository.getReceipt(transactionId);
      if (transaction != null) {
        emit(ReceiptLoaded(transaction));
      } else {
        emit(const ReceiptError('Struk transaksi tidak ditemukan'));
      }
    } catch (e) {
      emit(ReceiptError('Gagal memuat struk: $e'));
    }
  }
}

