import 'package:flutter/foundation.dart';
import 'package:vendora/core/data/repositories/seller_repository.dart';
import 'package:vendora/models/seller_model.dart';
import 'package:vendora/core/errors/failures.dart';

class SellerDashboardProvider with ChangeNotifier {
  final SellerRepository _sellerRepository;

  Seller? _currentSeller;
  SellerStats? _stats;
  bool _isLoading = false;
  String? _error;

  SellerDashboardProvider(this._sellerRepository);

  Seller? get currentSeller => _currentSeller;
  SellerStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isVerified => _currentSeller?.isApproved ?? false;

  Future<void> loadDashboardData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 1. Fetch Seller Profile
    final sellerResult = await _sellerRepository.getCurrentSeller(userId);

    await sellerResult.fold(
      (failure) async {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (seller) async {
        _currentSeller = seller;
        
        if (seller != null) {
          // 2. Fetch Stats if seller exists
          final statsResult = await _sellerRepository.getSellerStats(seller.id);
          statsResult.fold(
            (failure) {
               // Stats failed, but we have seller. Just show error or partial data?
               // Let's log it but keep seller data
               _error = "Failed to load stats: ${failure.message}";
            },
            (stats) {
              _stats = stats;
            },
          );
        } else {
             // User is not a seller yet? logic elsewhere handles this?
             // Or maybe "Unregistered" state.
        }
        
        _isLoading = false;
        notifyListeners();
      },
    );
  }
  
  void clear() {
      _currentSeller = null;
      _stats = null;
      _error = null;
      notifyListeners();
  }
}
