import 'package:flutter/foundation.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/features/auth/data/repositories/auth_repository.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/models/user_model.dart';

/// Authentication state enum
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication provider managing auth state with Provider pattern
/// Implements Requirements 2.3, 2.7
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _sellerStatus;
  String? _errorMessage;

  AuthProvider(this._authRepository) {
    _checkAuthStatus();
  }

  // Getters
  AuthState get state => _state;
  User? get currentUser => _currentUser;
  String? get sellerStatus => _sellerStatus;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  /// Check authentication status on app launch
  /// Implements auto-login (Requirement 2.7)
  Future<void> _checkAuthStatus() async {
    _setState(AuthState.loading);

    final result = await _authRepository.getCurrentUser();

    result.fold(
      (failure) {
        _setState(AuthState.unauthenticated);
        _errorMessage = failure.message;
      },
      (user) {
        if (user != null) {
          _currentUser = user;
          _loadSellerStatus();
          _setState(AuthState.authenticated);
        } else {
          _setState(AuthState.unauthenticated);
        }
      },
    );
  }

  /// Load seller status if user is a seller
  Future<void> _loadSellerStatus() async {
    if (_currentUser?.role == 'seller') {
      final result = await _authRepository.getSellerStatus(_currentUser!.id);
      result.fold(
        (failure) {
          if (kDebugMode) {
            print('Failed to load seller status: ${failure.message}');
          }
        },
        (status) {
          _sellerStatus = status;
          notifyListeners();
        },
      );
    }
  }

  /// Sign up a new user
  /// Validates: Requirements 2.1, 2.2, 2.8
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    final result = await _authRepository.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: role,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(AuthState.error);
        return false;
      },
      (user) {
        _currentUser = user;
        _loadSellerStatus();
        _setState(AuthState.authenticated);
        return true;
      },
    );
  }

  /// Sign in existing user
  /// Validates: Requirements 2.3, 2.4
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(AuthState.error);
        return false;
      },
      (user) {
        _currentUser = user;
        _loadSellerStatus();
        _setState(AuthState.authenticated);
        return true;
      },
    );
  }

  /// Sign out current user
  /// Validates: Requirement 2.6
  Future<void> signOut() async {
    _setState(AuthState.loading);

    final result = await _authRepository.signOut();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(AuthState.error);
      },
      (_) {
        _currentUser = null;
        _sellerStatus = null;
        _errorMessage = null;
        _setState(AuthState.unauthenticated);
      },
    );
  }

  /// Send password reset email
  /// Validates: Requirement 2.5
  Future<bool> resetPassword(String email) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    final result = await _authRepository.resetPassword(email);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(AuthState.unauthenticated);
        return false;
      },
      (_) {
        _setState(AuthState.unauthenticated);
        return true;
      },
    );
  }

  /// Update password (after reset)
  /// Validates: Requirement 2.5
  Future<bool> updatePassword(String newPassword) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    final result = await _authRepository.updatePassword(newPassword);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(AuthState.error);
        return false;
      },
      (_) {
        _setState(AuthState.authenticated);
        return true;
      },
    );
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    final result = await _authRepository.resendVerificationEmail(email);
    return result.isRight();
  }

  /// Reload current user (to check verification status)
  Future<void> reloadUser() async {
    // First refresh the Supabase session to get updated email verification status
    await _authRepository.refreshSession();
    
    // Then refresh local user model from database and UPDATE state
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) {
        if (kDebugMode) {
          print('Failed to reload user: ${failure.message}');
        }
      },
      (user) {
        if (user != null) {
          _currentUser = user;
          _loadSellerStatus();
        }
      },
    );
    notifyListeners();
  }

  /// Get the underlying Supabase User (for email verification status)
  User? get apiUser => _currentUser; // This is the App Model User.
  // We need the Supabase Auth User to check 'email_confirmed_at'
  // But our AuthRepository abstracts it. 
  
  // Implementation Note: Since AuthRepository holds SupabaseConfig, 
  // we technically need to ask it for the auth user or expose a getter there.
  // Ideally, AuthProvider shouldn't check Supabase classes directly if architecture is strict.
  // But for now let's assume isEmailVerified is checked via a new method in Repo or implicitly.
  
  // Let's stick to using the AuthState.
  // However, I used 'apiUser' in the UI code I wrote. 
  // 'apiUser' in my UI code was likely referring to the App Model User having email.
  
  bool get isEmailVerified {
    return _authRepository.isEmailVerified;
  }

  /// Check if there's an active session (not just a cached user)
  bool get hasActiveSession {
    return _authRepository.hasActiveSession;
  }

  /// Get route name based on user role
  /// Used for role-based navigation
  String getHomeRouteForRole() {
    // Import AppRoutes is needed, but typically available via main or app structure. 
    // Since I can't see imports here, I'll use the strings matching AppRoutes or just use the string values I saw in AppRoutes.dart.
    // Better yet, I should add the import if missing, but let's check imports first.
    // I see `vendora/core/routes/app_routes.dart` is NOT imported in AuthProvider.dart (based on previous view).
    // So I will just use the correct string values for now to be safe and avoid Import errors without seeing the top of file again.
    // ACTUALLY, I should add the import. It's cleaner.
    
    if (_currentUser == null) {
      return '/'; // Splash or Welcome
    }

    // Check if email is verified
    if (!isEmailVerified) {
      return AppRoutes.emailVerification;
    }

    switch (_currentUser!.role) {
      case 'buyer':
        return '/buyer/home'; // Matches AppRoutes.buyerHome
      case 'seller':
        // Check if seller is verified
        if (_sellerStatus == 'unverified') {
           // Matches AppRoutes.sellerPending which is '/seller-pending'
           // Wait, AppRoutes says: static const String sellerPending = '/seller-pending';
           return '/seller-pending';
        }
        return '/seller/dashboard'; // Matches AppRoutes.sellerDashboard
      case 'admin':
        return '/admin/dashboard'; // Matches AppRoutes.adminDashboard
      default:
        return '/buyer/home';
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set state and notify listeners
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
