import 'package:flutter/foundation.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';
import 'package:vendora/models/user_entity.dart';

/// Provider for managing User Management feature state
/// Handles user listing with filters and banning operations
class UserManagementProvider extends ChangeNotifier {
  final IAdminRepository _adminRepository;

  UserManagementProvider(this._adminRepository);

  // State
  List<UserEntity> _users = [];
  bool _isLoading = false;
  String? _error;
  UserRole? _roleFilter;
  bool? _isActiveFilter;

  // Getters
  List<UserEntity> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole? get roleFilter => _roleFilter;
  bool? get isActiveFilter => _isActiveFilter;

  // Computed properties
  int get activeCount => _users.where((u) => u.isActive).length;
  int get bannedCount => _users.where((u) => !u.isActive).length;
  int get buyerCount => _users.where((u) => u.role == UserRole.buyer).length;
  int get sellerCount => _users.where((u) => u.role == UserRole.seller).length;

  /// Load users from repository with optional filters
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _adminRepository.getUsers(
      roleFilter: _roleFilter,
      isActiveFilter: _isActiveFilter,
    );

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (users) {
        _users = users;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Set filter for user role (buyer/seller)
  void setRoleFilter(UserRole? role) {
    _roleFilter = role;
    notifyListeners();
    loadUsers();
  }

  /// Set filter for active/banned status
  void setActiveFilter(bool? isActive) {
    _isActiveFilter = isActive;
    notifyListeners();
    loadUsers();
  }

  /// Clear all filters
  void clearFilters() {
    _roleFilter = null;
    _isActiveFilter = null;
    notifyListeners();
    loadUsers();
  }

  /// Ban a user - sets isActive to false and revokes session
  /// Returns true if successful, false otherwise
  Future<bool> banUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _adminRepository.banUser(userId);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Update local state - mark user as inactive
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isActive: false);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  /// Ban a seller - sets seller and user isActive to false, hides all products
  /// Returns true if successful, false otherwise
  Future<bool> banSeller(String sellerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _adminRepository.banSeller(sellerId);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Reload users to get updated status
        loadUsers();
        return true;
      },
    );
  }

  /// Search users by name or email (client-side filtering)
  List<UserEntity> searchUsers(String query) {
    if (query.isEmpty) return _users;
    final lowerQuery = query.toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred';
  }
}
