import 'package:flutter/foundation.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';
import 'package:vendora/models/dispute.dart';

/// Provider for managing dispute state and operations
/// Handles fetching disputes, filtering by status, and resolving disputes
class DisputeProvider extends ChangeNotifier {
  final IAdminRepository _adminRepository;

  DisputeProvider({required IAdminRepository adminRepository})
      : _adminRepository = adminRepository;

  List<Dispute> _disputes = [];
  Dispute? _selectedDispute;
  bool _isLoading = false;
  String? _errorMessage;
  DisputeStatus? _currentFilter;

  List<Dispute> get disputes => _disputes;
  Dispute? get selectedDispute => _selectedDispute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DisputeStatus? get currentFilter => _currentFilter;

  /// Fetch all disputes with optional status filter
  Future<void> fetchDisputes({DisputeStatus? status}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentFilter = status;
    notifyListeners();

    final result = await _adminRepository.getDisputes(status: status);

    result.fold(
      (failure) {
        _errorMessage = _getFailureMessage(failure);
        _disputes = [];
      },
      (disputes) {
        _disputes = disputes;
        _errorMessage = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch and select a specific dispute by ID
  Future<void> selectDispute(String disputeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _adminRepository.getDisputeById(disputeId);

    result.fold(
      (failure) {
        _errorMessage = _getFailureMessage(failure);
        _selectedDispute = null;
      },
      (dispute) {
        _selectedDispute = dispute;
        _errorMessage = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Resolve dispute by refunding the buyer
  /// This cancels the order and marks dispute as resolved
  Future<bool> refundBuyer(String disputeId, String resolution) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _adminRepository.resolveDisputeRefundBuyer(
      disputeId,
      resolution,
    );

    bool success = false;
    result.fold(
      (failure) {
        _errorMessage = _getFailureMessage(failure);
      },
      (_) {
        success = true;
        _errorMessage = null;
        // Refresh the disputes list
        fetchDisputes(status: _currentFilter);
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Resolve dispute by releasing funds to seller
  /// This keeps the order as delivered and marks dispute as resolved
  Future<bool> releaseSeller(String disputeId, String resolution) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _adminRepository.resolveDisputeReleaseSeller(
      disputeId,
      resolution,
    );

    bool success = false;
    result.fold(
      (failure) {
        _errorMessage = _getFailureMessage(failure);
      },
      (_) {
        success = true;
        _errorMessage = null;
        // Refresh the disputes list
        fetchDisputes(status: _currentFilter);
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Clear selected dispute
  void clearSelectedDispute() {
    _selectedDispute = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error message from failure
  String _getFailureMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network.';
    } else if (failure is CacheFailure) {
      return 'Failed to load cached data.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
