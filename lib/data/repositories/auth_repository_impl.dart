import 'package:inventrack/data/datasources/auth_remote_data_source.dart';
import 'package:inventrack/domain/entities/user_entity.dart';
import 'package:inventrack/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    return await remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String handle,
    required String role,
  }) async {
    await remoteDataSource.signUp(
      email: email,
      password: password,
      name: name,
      handle: handle,
      role: role,
    );
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  @override
  UserEntity? getCurrentUser() {
    final user = remoteDataSource.getCurrentUser();
    if (user != null) {
      return UserEntity(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        handle: 'user',
      );
    }
    return null;
  }
}
