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
  }

  Future<void> _onLogin(AuthEventLogin event, Emitter<AuthState> emit) async {
    try {
      emit(AuthStateLoading());
      await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.pass,
      );
      emit(AuthStateLogin());
    } catch (e) {
      emit(_handleError(e));
    }
  }

  Future<void> _onSignUp(AuthEventSignUp event, Emitter<AuthState> emit) async {
    try {
      emit(AuthStateLoading());
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
    } catch (e) {
      emit(_handleError(e));
    }
  }

  Future<void> _onLogout(AuthEventLogout event, Emitter<AuthState> emit) async {
    try {
      emit(AuthStateLoading());
      await _auth.signOut();
      emit(AuthStateLogout());
    } catch (e) {
      emit(_handleError(e));
    }
  }

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
