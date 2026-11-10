import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/discount.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'checkout_state.dart';

/// Cubit untuk mengelola proses pembayaran dan penyimpanan transaksi (F7 & D3 PRD).
class CheckoutCubit extends Cubit<CheckoutState> {
  final TransactionRepository _transactionRepository;

  CheckoutCubit(this._transactionRepository) : super(const CheckoutState());

  /// Mengatur jenis dan nilai diskon (persen atau nominal).
  void setDiscount(DiscountType? type, int value) {
    if (type == null) {
      emit(
        state.copyWith(
          clearDiscountType: true,
          discountValue: 0,
        ),
      );
    } else {
      emit(
        state.copyWith(
          discountType: type,
          discountValue: value,
        ),
      );
    }
  }

  /// Mengatur jumlah uang yang diterima dari pelanggan (manual atau lewat Quick Cash).
  void setPaidAmount(int amount) {
    emit(state.copyWith(paidAmount: amount));
  }

  /// Mereset state checkout ke awal untuk transaksi baru.
  void reset() {
    emit(const CheckoutState());
  }

  /// Memproses penyimpanan transaksi atomik ke database SQLite (B5 PRD).
  Future<bool> processPayment({
    required Cart cart,
    required CheckoutTotals totals,
    required int changeAmount,
  }) async {
    if (cart.isEmpty) {
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          errorMessage: 'Keranjang belanja kosong',
        ),
      );
      return false;
    }

    if (state.paidAmount < totals.total) {
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          errorMessage: 'Uang yang dibayarkan kurang dari total belanja',
        ),
      );
      return false;
    }

    try {
      emit(state.copyWith(status: CheckoutStatus.submitting));

      final txId = await _transactionRepository.saveTransaction(
        cart: cart,
        totals: totals,
        paid: state.paidAmount,
        changeAmount: changeAmount,
      );

      emit(
        state.copyWith(
          status: CheckoutStatus.success,
          transactionId: txId,
        ),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          errorMessage: msg,
        ),
      );
      return false;
    }
  }

  /// Menghasilkan rekomendasi nominal pembulatan di atas total belanja (D3 Quick Cash).
  /// Pecahan standar rupiah: 10.000, 20.000, 50.000, 100.000 tanpa duplikat.
  static List<int> getQuickCashSuggestions(int total) {
    if (total <= 0) return [];

    final suggestions = <int>{};
    const denominations = [10000, 20000, 50000, 100000];

    for (final d in denominations) {
      if (d > total) {
        suggestions.add(d);
      } else {
        final rounded = ((total + d - 1) ~/ d) * d;
        if (rounded > total) {
          suggestions.add(rounded);
        }
      }
    }

    final sorted = suggestions.toList()..sort();
    // Ambil maksimal 3 opsi pembulatan terdekat agar antarmuka tetap bersih
    return sorted.take(3).toList();
  }
}

