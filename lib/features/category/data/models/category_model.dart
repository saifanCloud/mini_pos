import '../../domain/entities/category.dart';

/// Model untuk konversi data antara SQLite (Map) dan entity [Category].
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
    };
  }
}

