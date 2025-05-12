import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventrack/utils/user_role.dart';

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
    await _authMethods(
      emit: emit,
      action: () async {
        final UserCredential userCredential =
            await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.pass,
        );

        final User? user = userCredential.user;
        if (user == null) {
          throw Exception("User tidak ditemukan.");
        }

        // 🔍 Ambil handle dan role dari Firestore
        final QuerySnapshot snapshot = await _firestore
            .collectionGroup("users")
            .where("uid", isEqualTo: user.uid)
            .get();

        if (snapshot.docs.isEmpty) {
          throw Exception("Data user tidak ditemukan di Firestore.");
        }

        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final handle = data['handle'] ?? 'user';

        emit(AuthStateAuthenticated(
            uid: user.uid, email: user.email ?? '', handle: handle));
      },
    );
  }

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
          'handle': event.handle,
        });

        emit(AuthStateSignUp());
      },
    );
  }

  Future<void> _onLogout(AuthEventLogout event, Emitter<AuthState> emit) async {
    await _authMethods(
      emit: emit,
      action: () async {
        await _auth.signOut();
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
