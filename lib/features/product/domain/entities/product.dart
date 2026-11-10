import 'package:equatable/equatable.dart';

/// Entity Product — layer domain murni Dart.
class Product extends Equatable {
  final int id;
  final int? categoryId;
  final String? categoryName; // nama kategori untuk kemudahan tampilan di UI
  final String name;
  final int price; // dalam Rupiah (integer tanpa desimal)
  final int stock;
  final String? photoPath; // nama file foto di dokumen aplikasi
  final List<int> addonIds; // daftar ID add-on yang terhubung
  final bool isDeleted;

  const Product({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.name,
    required this.price,
    required this.stock,
    this.photoPath,
    this.addonIds = const [],
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        categoryName,
        name,
        price,
        stock,
        photoPath,
        addonIds,
        isDeleted,
      ];
}

