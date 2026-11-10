import 'package:equatable/equatable.dart';
import 'cart_line.dart';

/// Entity Cart yang membungkus kumpulan baris keranjang belanja.
class Cart extends Equatable {
  final List<CartLine> lines;

  const Cart({this.lines = const []});

  /// Total subtotal seluruh baris di keranjang (sebelum diskon).
  int get subtotal => lines.fold<int>(0, (sum, line) => sum + line.subtotal);

  /// Total kuantitas barang yang ada di keranjang.
  int get totalItems => lines.fold<int>(0, (sum, line) => sum + line.qty);

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  @override
  List<Object?> get props => [lines];
}

