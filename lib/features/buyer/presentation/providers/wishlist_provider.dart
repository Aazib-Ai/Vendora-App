import 'package:flutter/foundation.dart';
import 'package:vendora/core/data/repositories/wishlist_repository.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/models/wishlist_item.dart';
import 'package:vendora/models/product.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistRepository _wishlistRepository;
  final ProductRepository _productRepository;
  
  List<WishlistItem> _wishlistItems = [];
  Map<String, Product> _wishlistProducts = {};
  bool _isLoading = false;
  String? _error;

  WishlistProvider({
    required WishlistRepository wishlistRepository,
    required ProductRepository productRepository,
  }) : _wishlistRepository = wishlistRepository,
       _productRepository = productRepository;

  List<WishlistItem> get wishlistItems => _wishlistItems;
  Map<String, Product> get wishlistProducts => _wishlistProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.productId == productId);
  }

  Future<void> loadWishlist(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _wishlistRepository.getWishlist(userId);

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (items) async {
        _wishlistItems = items;
        await _loadProductsForWishlist();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadProductsForWishlist() async {
    for (final item in _wishlistItems) {
      if (!_wishlistProducts.containsKey(item.productId)) {
        final result = await _productRepository.getProductById(item.productId);
        result.fold(
          (failure) => null, // Ignore failure for individual products
          (product) {
            _wishlistProducts[item.productId] = product;
          },
        );
      }
    }
  }

  Future<void> addToWishlist(String userId, Product product) async {
    // Optimistic update
    final tempItem = WishlistItem(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      productId: product.id,
      priceAtAdd: product.currentPrice,
      createdAt: DateTime.now(),
    );
    
    _wishlistItems.add(tempItem);
    _wishlistProducts[product.id] = product;
    notifyListeners();

    final result = await _wishlistRepository.addToWishlist(userId, product.id, product.currentPrice);

    result.fold(
      (failure) {
        _wishlistItems.remove(tempItem);
        _error = failure.message;
        notifyListeners();
      },
      (newItem) {
        final index = _wishlistItems.indexOf(tempItem);
        if (index != -1) {
          _wishlistItems[index] = newItem;
        } else {
             // Fallback if list changed
             _wishlistItems.add(newItem);
        }
        notifyListeners();
      },
    );
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    // Optimistic update
    final index = _wishlistItems.indexWhere((item) => item.productId == productId);
    WishlistItem? removedItem;
    if (index != -1) {
      removedItem = _wishlistItems.removeAt(index);
      notifyListeners();
    }

    final result = await _wishlistRepository.removeFromWishlist(userId, productId);

    result.fold(
      (failure) {
        if (removedItem != null) {
          _wishlistItems.insert(index, removedItem);
        }
        _error = failure.message;
        notifyListeners();
      },
      (_) {
        // Success, nothing to do as we already updated UI
      },
    );
  }
}
