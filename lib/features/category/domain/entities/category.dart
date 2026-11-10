import 'package:equatable/equatable.dart';

/// Entity Category — layer domain murni Dart.
class Category extends Equatable {
  final int id;
  final String name;

  const Category({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

