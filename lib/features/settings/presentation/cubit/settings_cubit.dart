import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/store_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

/// Cubit untuk mengelola pembacaan dan pembaruan pengaturan toko (F10 PRD).
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsCubit(this._settingsRepository) : super(const SettingsState());

  /// Membaca data pengaturan toko dari database SQLite.
  Future<void> loadSettings() async {
    try {
      emit(state.copyWith(status: SettingsStatus.loading));
      final settings = await _settingsRepository.getStoreSettings();
      emit(
        state.copyWith(
          status: SettingsStatus.loaded,
          settings: settings,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: 'Gagal memuat pengaturan toko: $e',
        ),
      );
    }
  }

  /// Memperbarui informasi nama dan alamat toko.
  Future<bool> saveStoreSettings({
    required String storeName,
    String? address,
  }) async {
    final trimmedName = storeName.trim();
    if (trimmedName.isEmpty) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: 'Nama toko tidak boleh kosong',
        ),
      );
      return false;
    }

    try {
      emit(state.copyWith(status: SettingsStatus.saving));

      final newSettings = StoreSettings(
        id: 1,
        storeName: trimmedName,
        address: address?.trim(),
      );

      await _settingsRepository.updateStoreSettings(newSettings);

      emit(
        state.copyWith(
          status: SettingsStatus.success,
          settings: newSettings,
          errorMessage: null,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: 'Gagal menyimpan pengaturan: $e',
        ),
      );
      return false;
    }
  }
}

