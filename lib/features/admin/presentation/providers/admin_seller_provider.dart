import 'package:flutter/foundation.dart';
import 'package:vendora/core/data/repositories/seller_repository.dart';
import 'package:vendora/models/seller_model.dart';
import 'package:vendora/core/errors/failures.dart';

/// Provider for managing all sellers in admin panel
/// Handles loading, approving, and rejecting sellers
class AdminSellerProvider extends ChangeNotifier {
  final ISellerRepository _sellerRepository;

  AdminSellerProvider(this._sellerRepository);

  List<Seller> _sellers = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'All';

  List<Seller> get sellers {
    if (_selectedFilter == 'All') {
      return _sellers;
    }
    return _sellers.where((s) => 
      s.status.toLowerCase() == _selectedFilter.toLowerCase()
    ).toList();
  }

  List<Seller> get allSellers => _sellers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;

  int get totalCount => _sellers.length;
  int get pendingCount => _sellers.where((s) => s.status.toLowerCase() == 'pending' || s.status.toLowerCase() == 'unverified').length;
  int get approvedCount => _sellers.where((s) => s.status.toLowerCase() == 'active' || s.status.toLowerCase() == 'approved').length;
  int get suspendedCount => _sellers.where((s) => s.status.toLowerCase() == 'suspended').length;

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadSellers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _sellerRepository.getAllSellers();

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (sellers) {
        _sellers = sellers;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> approveSeller(String sellerId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _sellerRepository.approveSeller(sellerId);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Update local list - change status to active
        final index = _sellers.indexWhere((s) => s.id == sellerId);
        if (index != -1) {
          _sellers[index] = _sellers[index].copyWith(status: 'active');
        }
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> rejectSeller(String sellerId, String reason) async {
    _isLoading = true;
    notifyListeners();

    final result = await _sellerRepository.rejectSeller(sellerId, reason);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Update local list - change status to rejected
        final index = _sellers.indexWhere((s) => s.id == sellerId);
        if (index != -1) {
          _sellers[index] = _sellers[index].copyWith(status: 'rejected');
        }
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> suspendSeller(String sellerId, String reason) async {
    _isLoading = true;
    notifyListeners();

    final result = await _sellerRepository.suspendSeller(sellerId, reason);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Update local list - change status to suspended
        final index = _sellers.indexWhere((s) => s.id == sellerId);
        if (index != -1) {
          _sellers[index] = _sellers[index].copyWith(status: 'suspended');
        }
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> reactivateSeller(String sellerId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _sellerRepository.reactivateSeller(sellerId);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Update local list - change status back to active
        final index = _sellers.indexWhere((s) => s.id == sellerId);
        if (index != -1) {
          _sellers[index] = _sellers[index].copyWith(status: 'active');
        }
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<void> refresh() async {
    await loadSellers();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred';
  }
}

