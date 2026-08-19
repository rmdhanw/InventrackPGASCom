abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentikasi gagal']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal memuat cache lokal']);
}
