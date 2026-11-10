import '../../../../core/database/database_helper.dart';
import '../../domain/entities/store_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Implementasi [SettingsRepository] menggunakan SQLite.
class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseHelper _dbHelper;

  SettingsRepositoryImpl(this._dbHelper);

  @override
  Future<StoreSettings> getStoreSettings() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'store_settings',
      where: 'id = 1',
    );

    if (rows.isNotEmpty) {
      final map = rows.first;
      return StoreSettings(
        id: (map['id'] as int?) ?? 1,
        storeName: (map['store_name'] as String?) ?? 'Toko Saya',
        address: map['address'] as String?,
      );
    }

    // Nilai bawaan jika belum ada
    return const StoreSettings(
      id: 1,
      storeName: 'Toko Saya',
      address: '',
    );
  }

  @override
  Future<void> updateStoreSettings(StoreSettings settings) async {
    final db = await _dbHelper.database;
    await db.update(
      'store_settings',
      {
        'store_name': settings.storeName.trim(),
        'address': settings.address?.trim(),
      },
      where: 'id = 1',
    );
  }
}

