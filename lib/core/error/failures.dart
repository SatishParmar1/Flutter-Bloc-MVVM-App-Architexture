sealed class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({String message = 'No internet connection'}) : super(message);
}

class ServerFailure extends AppFailure {
  final int? statusCode;
  const ServerFailure({required String message, this.statusCode}) : super(message);
}

class CacheFailure extends AppFailure {
  const CacheFailure({String message = 'Cache operation failed'}) : super(message);
}

class AuthFailure extends AppFailure {
  const AuthFailure({String message = 'Authentication failed'}) : super(message);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({String message = 'An unexpected error occurred'}) : super(message);
}
