import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/features/admin/domain/entities/admin_stats.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final IAdminRepository _adminRepository;

  AdminDashboardProvider(this._adminRepository);

  AdminStats _stats = AdminStats.empty();
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AdminStats>? _statsSubscription;

  AdminStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load initial dashboard statistics
  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _adminRepository.getDashboardStats();

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (stats) {
        _stats = stats;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Subscribe to real-time statistics updates
  void subscribeToStats() {
    _statsSubscription?.cancel();
    _statsSubscription = _adminRepository.watchDashboardStats().listen(
      (stats) {
        _stats = stats;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  /// Refresh statistics manually
  Future<void> refreshStats() async {
    await loadStats();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection';
    }
    return 'An unexpected error occurred';
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }
}
