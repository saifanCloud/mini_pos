import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pos/features/settings/domain/entities/store_settings.dart';
import 'package:mini_pos/features/settings/domain/repositories/settings_repository.dart';
import 'package:mini_pos/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:mini_pos/features/settings/presentation/cubit/settings_state.dart';

class MockSettingsRepository implements SettingsRepository {
  StoreSettings current = const StoreSettings(
    id: 1,
    storeName: 'Toko Saya',
    address: 'Jl. Utama',
  );

  @override
  Future<StoreSettings> getStoreSettings() async {
    return current;
  }

  @override
  Future<void> updateStoreSettings(StoreSettings settings) async {
    current = settings;
  }
}

void main() {
  group('SettingsCubit Tests (Tahap 12 & F10 PRD)', () {
    late MockSettingsRepository mockRepository;
    late SettingsCubit settingsCubit;

    setUp(() {
      mockRepository = MockSettingsRepository();
      settingsCubit = SettingsCubit(mockRepository);
    });

    tearDown(() {
      settingsCubit.close();
    });

    test('State awal SettingsCubit memiliki nilai bawaan', () {
      expect(settingsCubit.state.status, SettingsStatus.initial);
      expect(settingsCubit.state.settings.storeName, 'Toko Saya');
    });

    test('loadSettings sukses memuat pengaturan toko', () async {
      await settingsCubit.loadSettings();

      expect(settingsCubit.state.status, SettingsStatus.loaded);
      expect(settingsCubit.state.settings.storeName, 'Toko Saya');
      expect(settingsCubit.state.settings.address, 'Jl. Utama');
    });

    test('saveStoreSettings sukses memperbarui nama dan alamat toko', () async {
      final success = await settingsCubit.saveStoreSettings(
        storeName: 'Kopi Kenangan Baru',
        address: 'Jl. Melati No. 12',
      );

      expect(success, isTrue);
      expect(settingsCubit.state.status, SettingsStatus.success);
      expect(settingsCubit.state.settings.storeName, 'Kopi Kenangan Baru');
      expect(settingsCubit.state.settings.address, 'Jl. Melati No. 12');
      expect(mockRepository.current.storeName, 'Kopi Kenangan Baru');
    });

    test('saveStoreSettings menolak jika nama toko kosong', () async {
      final success = await settingsCubit.saveStoreSettings(
        storeName: '   ',
        address: 'Alamat Baru',
      );

      expect(success, isFalse);
      expect(settingsCubit.state.status, SettingsStatus.error);
      expect(settingsCubit.state.errorMessage, contains('tidak boleh kosong'));
      // Data lama tidak berubah
      expect(mockRepository.current.storeName, 'Toko Saya');
    });
  });
}

