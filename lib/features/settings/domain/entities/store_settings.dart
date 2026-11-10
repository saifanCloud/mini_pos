import 'package:equatable/equatable.dart';

/// Entity Pengaturan Toko (F10 PRD) — layer domain murni Dart.
class StoreSettings extends Equatable {
  final int id;
  final String storeName;
  final String? address;

  const StoreSettings({
    this.id = 1,
    required this.storeName,
    this.address,
  });

  StoreSettings copyWith({
    int? id,
    String? storeName,
    String? address,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [id, storeName, address];
}

