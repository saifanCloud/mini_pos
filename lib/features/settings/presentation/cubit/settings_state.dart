import 'package:equatable/equatable.dart';
import '../../domain/entities/store_settings.dart';

enum SettingsStatus { initial, loading, loaded, saving, success, error }

/// State untuk pengaturan toko (F10 PRD).
class SettingsState extends Equatable {
  final SettingsStatus status;
  final StoreSettings settings;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const StoreSettings(storeName: 'Toko Saya', address: ''),
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    StoreSettings? settings,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}

