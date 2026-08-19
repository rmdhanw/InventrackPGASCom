import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventrack/domain/repositories/auth_repository.dart';
import 'package:inventrack/utils/user_role.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthStateLogout()) {
    on<AuthEventLogin>(_onLogin);
    on<AuthEventSignUp>(_onSignUp);
    on<AuthEventLogout>(_onLogout);
  }

  Future<void> _onLogin(AuthEventLogin event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        final userEntity = await authRepository.login(
          email: event.email,
          password: event.pass,
        );

        emit(AuthStateAuthenticated(
          uid: userEntity.uid,
          email: userEntity.email,
          handle: userEntity.handle,
        ));
      },
    );
  }

  Future<void> _onSignUp(AuthEventSignUp event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        await authRepository.signUp(
          email: event.email,
          password: event.pass,
          name: event.name,
          handle: event.handle,
          role: event.role,
        );

        emit(AuthStateSignUp());
      },
    );
  }

  Future<void> _onLogout(AuthEventLogout event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        await authRepository.logout();
        emit(AuthStateLogout());
      },
    );
  }

  Future<void> _authMethods({
    required Emitter<AuthState> emit,
    required Future<void> Function() action,
  }) async {
    try {
      emit(AuthStateLoading());
      await action();
    } catch (e) {
      emit(_handleError(e));
    }
  }

  AuthState _handleError(dynamic error) {
    String errorMessage = "An unknown error occurred.";
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'Akun tidak ditemukan.';
          break;
        case 'wrong-password':
          errorMessage = 'Password salah.';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid.';
          break;
        default:
          errorMessage = error.message ?? errorMessage;
      }
    } else if (error is FirebaseException) {
      errorMessage = error.message ?? errorMessage;
    } else if (error is Exception) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
    }
    return AuthStateError(errorMessage);
  }
}
