import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthStateLogout()) {
    on<AuthEventLogin>(_onLogin);
    on<AuthEventSignUp>(_onSignUp);
    on<AuthEventLogout>(_onLogout);
    on<AuthEventRequestResetConfirmation>(_onRequestResetConfirmation);
    on<AuthEventForgotPassword>(_onForgotPassword);
  }

  Future<void> _onLogin(AuthEventLogin event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.pass,
        );
        emit(AuthStateLogin());
      },
    );
  }

  /// Fungsi untuk Register User Baru
  Future<void> _onSignUp(AuthEventSignUp event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.pass,
        );

        User? user = userCredential.user;
        if (user == null) {
          throw Exception("User tidak ditemukan setelah sign-up.");
        }

        await _firestore
            .collection("roles")
            .doc(event.role)
            .collection("users")
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'email': event.email,
          'name': event.name,
          'createdAt': FieldValue.serverTimestamp(),
          'handle': "user",
        });

        emit(AuthStateSignUp());
      },
    );
  }

  /// Fungsi untuk Logout
  Future<void> _onLogout(AuthEventLogout event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        await _auth.signOut();
        emit(AuthStateLogout());
      },
    );
  }

  /// Fungsi untuk Mengirim Email Reset Password
  Future<void> _onForgotPassword(
      AuthEventForgotPassword event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        await _auth.sendPasswordResetEmail(email: event.email);
        emit(AuthStateSuccess("Password reset email sent!"));
      },
    );
  }

  /// Fungsi untuk Mengirim Email Konfirmasi Reset Password
  Future<void> _onRequestResetConfirmation(
      AuthEventRequestResetConfirmation event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        ActionCodeSettings actionCodeSettings = ActionCodeSettings(
          url: 'https://yourapp.page.link/resetpassword',
          handleCodeInApp: true,
          androidPackageName: 'com.example.yourapp',
          androidInstallApp: true,
          androidMinimumVersion: '21',
          iOSBundleId: 'com.example.yourapp',
        );

        await _auth.sendSignInLinkToEmail(
          email: event.email,
          actionCodeSettings: actionCodeSettings,
        );

        emit(AuthStateSuccess(
            "A confirmation email has been sent. Please check your email."));
      },
    );
  }

  /// Fungsi General untuk Menangani Error dan Loading
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

  /// Fungsi untuk Menangani Error
  AuthState _handleError(dynamic error) {
    String errorMessage = "An unknown error occurred.";
    if (error is FirebaseAuthException) {
      errorMessage = error.message ?? errorMessage;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }
    return AuthStateError(errorMessage);
  }
}
