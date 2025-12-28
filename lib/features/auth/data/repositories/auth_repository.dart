import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/core/errors/exceptions.dart' as app_exceptions;
import 'package:vendora/models/user_model.dart' as app_models;

/// Authentication repository handling all auth operations with Supabase
/// Implements Requirements 2.1-2.8
class AuthRepository {
  final SupabaseConfig _supabaseConfig;

  AuthRepository(this._supabaseConfig);

  /// Sign up a new user with email, password, and role
  /// For sellers, creates entry in sellers table with status 'unverified'
  /// Validates: Requirements 2.1, 2.2, 2.8
  Future<Either<Failure, app_models.User>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role, // 'buyer' or 'seller'
  }) async {
    try {
      // 1. Create auth user in Supabase Auth with metadata
      // The database trigger 'on_auth_user_created' will automatically
      // create the user profile in 'users' and 'sellers' tables.
      final authResponse = await _supabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': role,
        },
      );

      if (authResponse.user == null) {
        return const Left(
          AuthFailure('Failed to create account', app_exceptions.AuthErrorType.unknown),
        );
      }

      // 2. Return user model
      // Note: We return the model immediately. The trigger handles DB insertion asynchronously.
      // In a real app, you might want to wait or listen for the public user profile creation,
      // but for this flow it's sufficient to assume success if auth succeeds.
      final user = app_models.User(
        id: authResponse.user!.id,
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

      if (kDebugMode) {
        print('✓ User signed up successfully: $email (role: $role)');
      }

      return Right(user);
    } on app_exceptions.AuthException catch (e) {
      if (kDebugMode) {
        print('✗ Sign up auth error: ${e.message}');
      }
      return Left(AuthFailure.fromException(e));
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('✗ Sign up database error: ${e.message}');
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Sign up error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Sign in existing user with email and password
  /// Validates: Requirements 2.3, 2.4
  Future<Either<Failure, app_models.User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Authenticate with Supabase
      final authResponse = await _supabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return const Left(
          AuthFailure('Invalid credentials', app_exceptions.AuthErrorType.invalidCredentials),
        );
      }

      // 2. Get user profile from database
      final user = await getCurrentUser();
      
      if (kDebugMode) {
        print('✓ User signed in successfully: $email');
      }

      return user.fold(
        (failure) => Left(failure),
        (userData) => userData != null ? Right(userData) : const Left(AuthFailure('User not found', app_exceptions.AuthErrorType.userNotFound)),
      );
    } on app_exceptions.AuthException catch (e) {
      if (kDebugMode) {
        print('✗ Sign in error: ${e.message}');
      }
      return Left(AuthFailure.fromException(e));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Sign in error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Sign out current user
  /// Validates: Requirement 2.6
  Future<Either<Failure, void>> signOut() async {
    try {
      await _supabaseConfig.auth.signOut();
      
      if (kDebugMode) {
        print('✓ User signed out successfully');
      }
      
      return const Right(null);
    } on app_exceptions.AuthException catch (e) {
      if (kDebugMode) {
        print('✗ Sign out error: ${e.message}');
      }
      return Left(AuthFailure.fromException(e));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Sign out error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Resend verification email
  Future<Either<Failure, void>> resendVerificationEmail(String email) async {
    try {
      // For Supabase, we can use resend() method on auth
      await _supabaseConfig.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      if (kDebugMode) {
        print('✓ Verification email resent to: $email');
      }

      return const Right(null);
    } on app_exceptions.AuthException catch (e) {
       if (kDebugMode) {
        print('✗ Resend verification error: ${e.message}');
      }
      return Left(AuthFailure.fromException(e));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Resend verification error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Send password reset email
  /// Validates: Requirement 2.5
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _supabaseConfig.auth.resetPasswordForEmail(email);
      
      if (kDebugMode) {
        print('✓ Password reset email sent to: $email');
      }
      
      return const Right(null);
    } on app_exceptions.AuthException catch (e) {
      if (kDebugMode) {
        print('✗ Password reset error: ${e.message}');
      }
      return Left(AuthFailure.fromException(e));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Password reset error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Update user password (after reset)
  /// Validates: Requirement 2.5
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      await _supabaseConfig.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      if (kDebugMode) {
        print('✓ Password updated successfully');
      }
      
      return const Right(null);
    } on app_exceptions.AuthException catch (e) {
      if (kDebugMode) {
        print('✗ Update password error: ${e.message}');
      }
      return Left(AuthFailure.fromException(e));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Update password error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get current authenticated user with profile data
  /// Returns null if no user is authenticated
  /// Validates: Requirement 2.7
  Future<Either<Failure, app_models.User?>> getCurrentUser() async {
    try {
      final authUser = _supabaseConfig.auth.currentUser;
      
      if (authUser == null) {
        return const Right(null);
      }

      // Fetch user profile from database
      final response = await _supabaseConfig
          .from('users')
          .select()
          .eq('id', authUser.id)
          .single();

      final user = app_models.User(
        id: response['id'] as String,
        name: response['name'] as String,
        email: response['email'] as String,
        phone: response['phone'] as String,
        role: response['role'] as String,
        address: response['address'] as String?,
        profileImageUrl: response['profile_image_url'] as String?,
      );

      return Right(user);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('✗ Get current user error: ${e.message}');
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Get current user error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get seller status for current user (if they are a seller)
  /// Returns seller status: 'unverified', 'active', or 'rejected'
  /// Validates: Requirements 18.1, 18.2
  Future<Either<Failure, String?>> getSellerStatus(String userId) async {
    try {
      final response = await _supabaseConfig
          .from('sellers')
          .select('status')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return const Right(null); // Not a seller
      }

      return Right(response['status'] as String);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('✗ Get seller status error: ${e.message}');
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (kDebugMode) {
        print('✗ Get seller status error: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Listen to auth state changes
  /// Used for auto-login and session management
  Stream<AuthState> get authStateChanges {
    return _supabaseConfig.auth.onAuthStateChange;
  }

  /// Check if current user email is verified
  bool get isEmailVerified {
    final user = _supabaseConfig.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }
}
