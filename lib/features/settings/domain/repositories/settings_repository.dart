import '../entities/store_settings.dart';

/// Kontrak repository untuk pengaturan toko (F10 PRD).
abstract class SettingsRepository {
  /// Membaca data pengaturan toko (id = 1).
  Future<StoreSettings> getStoreSettings();

  /// Memperbarui nama dan alamat toko (id = 1).
  Future<void> updateStoreSettings(StoreSettings settings);
}

