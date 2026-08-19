import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventrack/core/constants/firestore_constants.dart';
import 'package:inventrack/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String handle,
    required String role,
  });
  Future<void> logout();
  User? getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final UserCredential userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = userCredential.user;
    if (user == null) {
      throw Exception("User tidak ditemukan.");
    }

    final QuerySnapshot snapshot = await firestore
        .collectionGroup(FirestoreConstants.usersCollection)
        .where("uid", isEqualTo: user.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception("Data user tidak ditemukan di Firestore.");
    }

    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data, user.uid);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String handle,
    required String role,
  }) async {
    final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = userCredential.user;
    if (user == null) {
      throw Exception("User tidak ditemukan setelah sign-up.");
    }

    await firestore
        .collection(FirestoreConstants.rolesCollection)
        .doc(role)
        .collection(FirestoreConstants.usersCollection)
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'handle': handle,
      'role': role,
    });
  }

  @override
  Future<void> logout() async {
    await auth.signOut();
  }

  @override
  User? getCurrentUser() {
    return auth.currentUser;
  }
}
