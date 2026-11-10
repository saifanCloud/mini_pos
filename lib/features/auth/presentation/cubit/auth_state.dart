import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// State autentikasi aplikasi.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum sesi diperiksa.
class AuthInitial extends AuthState {}

/// State saat proses verifikasi sesi, login, atau registrasi sedang berlangsung.
class AuthLoading extends AuthState {}

/// State ketika user memiliki sesi aktif.
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// State ketika tidak ada sesi aktif atau user telah logout.
class AuthUnauthenticated extends AuthState {}

/// State ketika proses login atau registrasi gagal.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

