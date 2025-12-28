import 'package:flutter/foundation.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';
import 'package:vendora/models/product.dart';
import 'package:vendora/core/errors/failures.dart';

/// Provider for managing product moderation state for admin users
/// Handles loading, approval, rejection, and hiding of products
class ProductModerationProvider extends ChangeNotifier {
  final IProductRepository _productRepository;
  final IAdminRepository _adminRepository;

  ProductModerationProvider({
    required IProductRepository productRepository,
    required IAdminRepository adminRepository,
  })  : _productRepository = productRepository,
        _adminRepository = adminRepository;

  List<Product> _pendingProducts = [];
  List<Product> _approvedProducts = [];
  List<Product> _rejectedProducts = [];
  List<Product> _hiddenProducts = [];
  List<Product> _reportedProducts = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Product> get pendingProducts => _pendingProducts;
  List<Product> get approvedProducts => _approvedProducts;
  List<Product> get rejectedProducts => _rejectedProducts;
  List<Product> get hiddenProducts => _hiddenProducts;
  List<Product> get reportedProducts => _reportedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount => _pendingProducts.length;
  int get approvedCount => _approvedProducts.length;
  int get rejectedCount => _rejectedProducts.length;
  int get hiddenCount => _hiddenProducts.length;
  int get reportedCount => _reportedProducts.length;

  /// Load all products and filter by status
  Future<void> loadAllProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all products with a large limit (include pending and inactive for moderation)
      final result = await _productRepository.getProducts(
        limit: 1000,
        onlyApproved: false,
        onlyActive: false,
      );

      result.fold(
        (failure) {
          _error = _mapFailureToMessage(failure);
          _isLoading = false;
          notifyListeners();
        },
        (products) {
          // Filter products by status and active state
          _pendingProducts = products
              .where((p) => p.status == ProductStatus.pending)
              .toList();
          
          _approvedProducts = products
              .where((p) => p.status == ProductStatus.approved && p.isActive)
              .toList();
          
          _rejectedProducts = products
              .where((p) => p.status == ProductStatus.rejected)
              .toList();
          
          _hiddenProducts = products
              .where((p) => !p.isActive && p.status == ProductStatus.approved)
              .toList();

          _reportedProducts = products
              .where((p) => p.status == ProductStatus.reported)
              .toList();
          
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve a pending product
  /// Requirements: 8.4
  Future<bool> approveProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _adminRepository.approveProduct(productId);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Move product from pending to approved list
        final product = _pendingProducts.firstWhere((p) => p.id == productId);
        _pendingProducts.removeWhere((p) => p.id == productId);
        _approvedProducts.add(product.copyWith(
          status: ProductStatus.approved,
          isActive: true,
        ));
        
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  /// Reject a pending product
  Future<bool> rejectProduct(String productId, String reason) async {
    _isLoading = true;
    notifyListeners();

    final result = await _adminRepository.rejectProduct(productId, reason);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Move product from pending to rejected list
        final product = _pendingProducts.firstWhere((p) => p.id == productId);
        _pendingProducts.removeWhere((p) => p.id == productId);
        _rejectedProducts.add(product.copyWith(
          status: ProductStatus.rejected,
        ));
        
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  /// Hide/ban an approved product
  /// Requirements: 8.7
  Future<bool> hideProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _adminRepository.hideProduct(productId);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Move product from approved to hidden list
        final product = _approvedProducts.firstWhere((p) => p.id == productId);
        _approvedProducts.removeWhere((p) => p.id == productId);
        _hiddenProducts.add(product.copyWith(
          isActive: false,
        ));
        
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  /// Unhide a hidden product (restore to approved)
  Future<bool> unhideProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    // Unhiding is the same as approving
    final result = await _adminRepository.approveProduct(productId);

    return result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Move product from hidden to approved list
        final product = _hiddenProducts.firstWhere((p) => p.id == productId);
        _hiddenProducts.removeWhere((p) => p.id == productId);
        _approvedProducts.add(product.copyWith(
          isActive: true,
        ));
        
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  /// Refresh all product lists
  Future<void> refresh() async {
    await loadAllProducts();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection';
    }
    return 'An unexpected error occurred';
  }
}
