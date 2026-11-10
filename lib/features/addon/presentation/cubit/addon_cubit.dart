import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/addon.dart';
import '../../domain/repositories/addon_repository.dart';
import 'addon_state.dart';

/// Cubit untuk mengelola state dan operasi CRUD add-on/topping.
class AddonCubit extends Cubit<AddonState> {
  final AddonRepository _addonRepository;

  AddonCubit(this._addonRepository) : super(AddonInitial());

  /// Muat semua add-on aktif.
  Future<void> loadAddons() async {
    emit(AddonLoading());
    try {
      final list = await _addonRepository.getAddons();
      emit(AddonLoaded(list));
    } catch (e) {
      emit(AddonFailure(_cleanErrorMessage(e)));
    }
  }

  /// Tambah add-on baru.
  Future<void> addAddon({
    required String name,
    required int price,
    required int stock,
  }) async {
    try {
      await _addonRepository.createAddon(
        name: name,
        price: price,
        stock: stock,
      );
      await loadAddons();
    } catch (e) {
      emit(AddonFailure(_cleanErrorMessage(e)));
      final list = await _addonRepository.getAddons();
      emit(AddonLoaded(list));
    }
  }

  /// Perbarui data add-on.
  Future<void> editAddon(Addon addon) async {
    try {
      await _addonRepository.updateAddon(addon);
      await loadAddons();
    } catch (e) {
      emit(AddonFailure(_cleanErrorMessage(e)));
      final list = await _addonRepository.getAddons();
      emit(AddonLoaded(list));
    }
  }

  /// Hapus add-on (soft delete).
  Future<void> deleteAddon(int id) async {
    try {
      await _addonRepository.deleteAddon(id);
      await loadAddons();
    } catch (e) {
      emit(AddonFailure(_cleanErrorMessage(e)));
      final list = await _addonRepository.getAddons();
      emit(AddonLoaded(list));
    }
  }

  String _cleanErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}

