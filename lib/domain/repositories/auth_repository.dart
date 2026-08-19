import 'package:inventrack/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String handle,
    required String role,
  });
  Future<void> logout();
  UserEntity? getCurrentUser();
}
