import 'exceptions.dart';

/// Base class for all failures in the application
/// Failures are used in the domain/business logic layer
/// They map from exceptions in the data layer
abstract class Failure {
  final String message;
  
  const Failure(this.message);
  
  @override
  String toString() => message;
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  
  const ValidationFailure(String message, {this.fieldErrors}) : super(message);
}

/// Failure when server/backend operations fail
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
  
  factory ServerFailure.fromException(ServerException exception) {
    return ServerFailure(exception.message);
  }
}

/// Failure when network operations fail
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
  
  factory NetworkFailure.fromException(NetworkException exception) {
    return NetworkFailure(exception.message);
  }
}

/// Failure when file operations fail
class FileFailure extends Failure {
  const FileFailure(String message) : super(message);
}

/// Failure when authentication fails
class AuthFailure extends Failure {
  final AuthErrorType type;
  
  const AuthFailure(String message, this.type) : super(message);
  
  factory AuthFailure.fromException(AuthException exception) {
    return AuthFailure(exception.message, exception.type);
  }
}

/// Failure when cache/local storage operations fail
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
  
  factory CacheFailure.fromException(CacheException exception) {
    return CacheFailure(exception.message);
  }
}

/// Failure when permission is denied
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
  
  factory PermissionFailure.fromException(PermissionException exception) {
    return PermissionFailure(exception.message);
  }
}

/// Failure when resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
  
  factory NotFoundFailure.fromException(NotFoundException exception) {
    return NotFoundFailure(exception.message);
  }
}
