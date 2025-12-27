import 'package:flutter/foundation.dart';
import 'package:vendora/core/data/repositories/seller_repository.dart';
import 'package:vendora/models/seller_model.dart';
import 'package:vendora/core/errors/failures.dart';

class AdminKYCProvider extends ChangeNotifier {
  final ISellerRepository _sellerRepository;

  AdminKYCProvider(this._sellerRepository);

  List<Seller> _unverifiedSellers = [];
  bool _isLoading = false;
  String? _error;

  List<Seller> get unverifiedSellers => _unverifiedSellers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUnverifiedSellers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _sellerRepository.getUnverifiedSellers();

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (sellers) {
        _unverifiedSellers = sellers;
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
        // Remove from local list
        _unverifiedSellers.removeWhere((s) => s.id == sellerId);
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
        // Remove from local list
        _unverifiedSellers.removeWhere((s) => s.id == sellerId);
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred';
  }
}
