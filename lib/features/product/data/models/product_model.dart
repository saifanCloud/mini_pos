import '../../domain/entities/product.dart';

/// Model untuk konversi data antara tabel SQLite `products` dan entity [Product].
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    super.categoryId,
    super.categoryName,
    required super.name,
    required super.price,
    required super.stock,
    super.photoPath,
    super.addonIds = const [],
    super.isDeleted = false,
  });

  factory ProductModel.fromMap(
    Map<String, dynamic> map, {
    List<int> addonIds = const [],
  }) {
    return ProductModel(
      id: map['id'] as int,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      name: map['name'] as String,
      price: map['price'] as int,
      stock: map['stock'] as int,
      photoPath: map['photo_path'] as String?,
      addonIds: addonIds,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'price': price,
      'stock': stock,
      'photo_path': photoPath,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'price': price,
      'stock': stock,
      'photo_path': photoPath,
      'is_deleted': 0,
    };
  }
}

