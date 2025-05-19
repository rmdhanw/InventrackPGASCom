part of 'auth_bloc.dart';

abstract class AuthEvent {}

// Event -> action / aksi / tindakan
// 1. AuthEventLogin -> melakukan tindakan login
// 2. AuthEventLogout -> melakukan tindakan logout
// 3. AuthEventSignUp -> melakukan pendaftaran
// 4. AuthEventRequestResetConfirmation -> meminta konfirmasi reset password
// 5. AuthEventForgotPassword -> mengatur ulang password

class AuthEventLogin extends AuthEvent {
  AuthEventLogin(this.email, this.pass);
  final String email;
  final String pass;
}

class AuthEventSignUp extends AuthEvent {
  AuthEventSignUp(this.email, this.pass, this.name, this.role, this.handle);
  final String email;
  final String pass;
  final String name;
  final String role;
  final String handle;
}

class AuthStateAuthenticated extends AuthState {
  final String uid;
  final String email;
  final String handle;

  AuthStateAuthenticated({
    required this.uid,
    required this.email,
    required this.handle,
  });
}

class AuthEventLogout extends AuthEvent {}

class AuthEventForgotPassword extends AuthEvent {
  final String email;
  AuthEventForgotPassword(this.email);
}

class AuthEventResetPassword extends AuthEvent {
  final String email;
  final String newPassword;

  AuthEventResetPassword(this.email, this.newPassword);
}
