import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../errors/exceptions.dart';

/// User role enumeration
enum UserRole {
  buyer,
  seller,
  admin,
}

/// User entity representing an authenticated user
class UserEntity {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: UserRole.values.byName(json['role'] as String),
      profileImageUrl: json['profile_image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
      'profile_image_url': profileImageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Abstract interface for authentication operations
/// Defines contract for auth repository implementations
abstract class IAuthRepository {
  /// Sign up a new user with email, password, and profile information
  /// Requirements: 2.1, 2.2, 2.8
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  });

  /// Sign in an existing user with email and password
  /// Requirements: 2.3, 2.4
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user and clear session
  /// Requirements: 2.6
  Future<Either<Failure, void>> signOut();

  /// Send password reset email to the specified email address
  /// Requirements: 2.5
  Future<Either<Failure, void>> resetPassword(String email);

  /// Get the currently authenticated user
  /// Requirements: 2.7
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of authentication state changes
  /// Requirements: 2.7
  Stream<AuthState> get authStateChanges;
}

/// Concrete implementation of authentication repository using Supabase
/// Handles session persistence and profile creation
class AuthRepository implements IAuthRepository {
  final SupabaseConfig _supabaseConfig;

  AuthRepository({SupabaseConfig? supabaseConfig})
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    try {
      // Sign up with Supabase Auth
      final response = await _supabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': role.name,
        },
      );

      if (response.user == null) {
        return const Left(AuthFailure(
          'Sign up failed. Please try again.',
          AuthErrorType.unknown,
        ));
      }

      // Create user profile in users table
      final profileData = {
        'id': response.user!.id,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role.name,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabaseConfig.from('users').insert(profileData);

      // If seller, create seller record with pending status
      if (role == UserRole.seller) {
        await _supabaseConfig.from('sellers').insert({
          'user_id': response.user!.id,
          'status': 'unverified',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      final user = UserEntity(
        id: response.user!.id,
        email: email,
        name: name,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      );

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure.fromException(e));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left(AuthFailure(
          'Invalid credentials',
          AuthErrorType.invalidCredentials,
        ));
      }

      // Fetch user profile from database
      final profileData = await _supabaseConfig
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      final user = UserEntity.fromJson(profileData);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure.fromException(e));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(
        e.toString(),
        AuthErrorType.unknown,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _supabaseConfig.auth.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure.fromException(e));
    } catch (e) {
      return Left(AuthFailure(
        e.toString(),
        AuthErrorType.unknown,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _supabaseConfig.auth.resetPasswordForEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure.fromException(e));
    } catch (e) {
      return Left(AuthFailure(
        e.toString(),
        AuthErrorType.unknown,
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final session = _supabaseConfig.auth.currentSession;
      if (session == null || session.user == null) {
        return const Right(null);
      }

      // Fetch user profile from database
      final profileData = await _supabaseConfig
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      final user = UserEntity.fromJson(profileData);
      return Right(user);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<AuthState> get authStateChanges {
    return _supabaseConfig.auth.onAuthStateChange;
  }
}
