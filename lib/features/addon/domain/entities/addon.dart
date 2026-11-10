import 'package:equatable/equatable.dart';

/// Entity Addon / Topping — layer domain murni Dart.
class Addon extends Equatable {
  final int id;
  final String name;
  final int price; // dalam Rupiah (integer tanpa desimal)
  final int stock;
  final bool isDeleted;

  const Addon({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [id, name, price, stock, isDeleted];
}

