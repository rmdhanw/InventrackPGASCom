import 'package:inventrack/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.handle,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      handle: json['handle'] ?? 'user',
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'handle': handle,
      if (role != null) 'role': role,
    };
  }
}
