part of 'auth_bloc.dart';

abstract class AuthState {}

// State -> kondisi saat ini
// 1. AuthStateLogin -> terautentikasi
// 2. AuthStateLogout -> tidak terautentikasi
// 3. AuthStateLoading -> loading ...
// 4. AuthStateError -> gagal login -> dapat error
// 5. AuthStateSuccess -> aksi berhasil dilakukan

class AuthStateLogin extends AuthState {}

class AuthStateLoading extends AuthState {}

class AuthStateLogout extends AuthState {}

class AuthStateSignUp extends AuthState {}

class AuthStateError extends AuthState {
  AuthStateError(this.message);
  final String message;
}

class AuthStateSuccess extends AuthState {
  final String message;
  AuthStateSuccess(this.message);
}
