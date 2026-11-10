import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../addon/domain/entities/addon.dart';
import '../../../product/domain/entities/product.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/cart_logic.dart';
import 'cart_state.dart';

/// Cubit untuk mengelola item di keranjang belanja kasir.
/// Menggunakan fungsi murni domain [CartLogic] dari Tahap 9.
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  /// Menambahkan produk dan kombinasi add-on ke keranjang belanja (F6 & B1 PRD).
  /// Mengembalikan [StockValidationResult] agar UI dapat menampilkan SnackBar
  /// jika stok tidak mencukupi (misal: "Stok Kopi Susu tinggal 2").
  StockValidationResult addToCart(
    Product product,
    List<Addon> selectedAddons,
  ) {
    // 1. Validasi stok bersama (B1 PRD)
    final result = CartLogic.canAddUnit(
      lines: state.lines,
      product: product,
      selectedAddons: selectedAddons,
      count: 1,
    );

    if (!result.isValid) {
      return result;
    }

    // 2. Gabungkan baris jika kombinasi sama, atau tambah baris baru
    final updatedLines = CartLogic.addOrMergeLine(
      state.lines,
      product,
      selectedAddons,
      qty: 1,
    );

    emit(state.copyWith(cart: Cart(lines: updatedLines)));
    return const StockValidationResult.valid();
  }

  /// Menambah kuantitas 1 baris item di keranjang.
  /// Memeriksa sisa stok bersama terlebih dahulu sebelum menaikkan qty.
  StockValidationResult incrementQty(int index) {
    if (index < 0 || index >= state.lines.length) {
      return const StockValidationResult.invalid('Item tidak valid');
    }

    final line = state.lines[index];

    // Validasi penambahan 1 unit
    final result = CartLogic.canAddUnit(
      lines: state.lines,
      product: line.product,
      selectedAddons: line.selectedAddons,
      count: 1,
    );

    if (!result.isValid) {
      return result;
    }

    final updatedLines = CartLogic.updateLineQty(
      state.lines,
      index,
      line.qty + 1,
    );

    emit(state.copyWith(cart: Cart(lines: updatedLines)));
    return const StockValidationResult.valid();
  }

  /// Mengurangi kuantitas 1 baris item di keranjang.
  /// Jika kuantitas menjadi 0, baris tersebut otomatis terhapus.
  void decrementQty(int index) {
    if (index < 0 || index >= state.lines.length) return;

    final line = state.lines[index];
    final updatedLines = CartLogic.updateLineQty(
      state.lines,
      index,
      line.qty - 1,
    );

    emit(state.copyWith(cart: Cart(lines: updatedLines)));
  }

  /// Menghapus satu baris item secara spesifik dari keranjang.
  void removeLine(int index) {
    if (index < 0 || index >= state.lines.length) return;

    final updatedLines = CartLogic.updateLineQty(
      state.lines,
      index,
      0,
    );

    emit(state.copyWith(cart: Cart(lines: updatedLines)));
  }

  /// Mengosongkan seluruh isi keranjang belanja.
  void clearCart() {
    emit(const CartState(cart: Cart()));
  }
}

