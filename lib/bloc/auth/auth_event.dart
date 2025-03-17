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
  AuthEventSignUp(this.email, this.pass, this.name, this.role);
  final String email;
  final String pass;
  final String name;
  final String role;
}

class AuthEventLogout extends AuthEvent {}

class AuthEventRequestResetConfirmation extends AuthEvent {
  final String email;
  AuthEventRequestResetConfirmation(this.email);
}

class AuthEventForgotPassword extends AuthEvent {
  final String email;
  AuthEventForgotPassword(this.email);
}

class AuthEventConfirmResetPassword extends AuthEvent {
  final String oobCode;
  final String newPassword;

  AuthEventConfirmResetPassword(
      {required this.oobCode, required this.newPassword});
}
