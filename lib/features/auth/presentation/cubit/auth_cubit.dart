import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit untuk mengelola state autentikasi dan sesi lokal aplikasi.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  /// Periksa sesi login yang tersimpan di database lokal.
  Future<void> checkSession() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  /// Masuk dengan username dan password.
  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(username, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(_cleanErrorMessage(e)));
    }
  }

  /// Daftarkan akun baru, lalu langsung buat sesi login aktif.
  Future<void> register({
    required String name,
    required String username,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(name, username, password);
      // Langsung login otomatis setelah berhasil mendaftar
      final user = await _authRepository.login(username, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(_cleanErrorMessage(e)));
    }
  }

  /// Hapus sesi lokal dan kembali ke state Unauthenticated.
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
    } catch (_) {}
    emit(AuthUnauthenticated());
  }

  String _cleanErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}

