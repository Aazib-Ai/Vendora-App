import 'package:flutter/material.dart';
import 'package:vendora/core/data/repositories/cart_repository.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/models/cart_item_model.dart';

/// Provider for managing shopping cart state
class CartProvider extends ChangeNotifier {
  final ICartRepository _cartRepository;

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  CartProvider(this._cartRepository);

  /// List of cart items
  List<CartItem> get items => _items;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Total number of items in cart
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Cart total amount
  double get cartTotal => _items.fold(0, (sum, item) => sum + item.total);

  /// Subtotal (same as total for now, can be used for pre-tax/shipping logic)
  double get subtotal => cartTotal;

  /// Load cart items for a user
  Future<void> loadCart(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _cartRepository.getCartItems(userId);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (items) {
        _items = items;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Add item to cart
  Future<void> addToCart({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _cartRepository.addCartItem(
      userId: userId,
      productId: productId,
      quantity: quantity,
    );

    await result.fold(
      (failure) async {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (newItem) async {
        // Optimistic update isn't ideal here as we need the full item from DB
        // But we can reload the cart or manually update the list if structure allows
        // For simplicity and correctness, we reload
        await loadCart(userId);
      },
    );
  }

  /// Update item quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    // Optimistic UI update could be done here, but let's stick to safe updates first
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _cartRepository.updateCartItem(
      cartItemId: cartItemId,
      quantity: quantity,
    );

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (updatedItem) {
        final index = _items.indexWhere((item) => item.id == cartItemId);
        if (index != -1) {
          _items[index] = updatedItem;
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _cartRepository.removeCartItem(cartItemId);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _items.removeWhere((item) => item.id == cartItemId);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _cartRepository.clearCart(userId);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _items.clear();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is NotFoundFailure) {
      return failure.message;
    } else {
      return 'Unexpected error occurred';
    }
  }
}
