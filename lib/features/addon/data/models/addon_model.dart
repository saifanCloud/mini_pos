import '../../domain/entities/addon.dart';

/// Model untuk konversi data antara tabel SQLite `addons` dan entity [Addon].
class AddonModel extends Addon {
  const AddonModel({
    required super.id,
    required super.name,
    required super.price,
    required super.stock,
    super.isDeleted = false,
  });

  factory AddonModel.fromMap(Map<String, dynamic> map) {
    return AddonModel(
      id: map['id'] as int,
      name: map['name'] as String,
      price: map['price'] as int,
      stock: map['stock'] as int,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'is_deleted': 0,
    };
  }
}

