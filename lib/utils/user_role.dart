enum UserRole {
  user,
  admin,
  superadmin,
}

UserRole getUserRoleFromString(String handle) {
  switch (handle.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'superadmin':
      return UserRole.superadmin;
    default:
      return UserRole.user;
  }
}
