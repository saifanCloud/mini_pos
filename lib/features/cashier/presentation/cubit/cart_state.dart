import 'package:equatable/equatable.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_line.dart';

/// State untuk keranjang belanja kasir.
class CartState extends Equatable {
  final Cart cart;

  const CartState({this.cart = const Cart()});

  List<CartLine> get lines => cart.lines;
  int get subtotal => cart.subtotal;
  int get totalItems => cart.totalItems;
  bool get isEmpty => cart.isEmpty;
  bool get isNotEmpty => cart.isNotEmpty;

  CartState copyWith({Cart? cart}) {
    return CartState(cart: cart ?? this.cart);
  }

  @override
  List<Object?> get props => [cart];
}

