import 'package:supabase_flutter/supabase_flutter.dart';

/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() {
    if (code != null) {
      return '$runtimeType($code): $message';
    }
    return '$runtimeType: $message';
  }
}

/// Server-side errors from Supabase
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.details,
  });

  factory ServerException.fromSupabaseError(dynamic error) {
    if (error is PostgrestException) {
      return ServerException(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }
    return ServerException(message: error.toString());
  }
}

/// Network connectivity errors
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Local cache/storage errors
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Authentication errors
class AuthException extends AppException {
  final AuthErrorType type;

  const AuthException({
    required super.message,
    required this.type,
    super.code,
    super.details,
  });

  factory AuthException.fromSupabaseAuthError(AuthException error) {
    final type = _mapAuthErrorType(error.message);
    return AuthException(
      message: error.message,
      type: type,
      code: error.toString(),
    );
  }

  static AuthErrorType _mapAuthErrorType(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('invalid') && lowerMessage.contains('credentials')) {
      return AuthErrorType.invalidCredentials;
    }
    if (lowerMessage.contains('email') && lowerMessage.contains('not') && lowerMessage.contains('verified')) {
      return AuthErrorType.emailNotVerified;
    }
    if (lowerMessage.contains('user') && lowerMessage.contains('not') && lowerMessage.contains('found')) {
      return AuthErrorType.userNotFound;
    }
    if (lowerMessage.contains('password') && (lowerMessage.contains('weak') || lowerMessage.contains('too short'))) {
      return AuthErrorType.weakPassword;
    }
    if (lowerMessage.contains('email') && lowerMessage.contains('already') && lowerMessage.contains('use')) {
      return AuthErrorType.emailInUse;
    }
    if (lowerMessage.contains('session') && lowerMessage.contains('expired')) {
      return AuthErrorType.sessionExpired;
    }
    
    return AuthErrorType.unknown;
  }
}

/// Types of authentication errors
enum AuthErrorType {
  invalidCredentials,
  emailNotVerified,
  userNotFound,
  weakPassword,
  emailInUse,
  sessionExpired,
  unknown,
}

/// Validation errors (client-side)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors,
    super.code,
    super.details,
  });
}

/// File upload/storage errors
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.details,
  });

  factory StorageException.fromSupabaseStorageError(StorageException error) {
    return StorageException(
      message: error.message,
      code: error.toString(),
    );
  }
}

/// Permission/authorization errors
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.details,
  });
}

/// Resource not found errors
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.details,
  });
}
