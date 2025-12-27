import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';

/// Cart item entity
class CartItem {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final DateTime createdAt;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
    required this.createdAt,
  });

  double get total => quantity * unitPrice;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Abstract interface for cart operations
/// Defines contract for cart repository implementations
abstract class ICartRepository {
  /// Get all cart items for a user
  /// Requirements: 6.4
  Future<Either<Failure, List<CartItem>>> getCartItems(String userId);

  /// Add a product to cart
  /// Requirements: 6.1
  Future<Either<Failure, CartItem>> addCartItem({
    required String userId,
    required String productId,
    required int quantity,
  });

  /// Update cart item quantity
  /// Requirements: 6.2
  Future<Either<Failure, CartItem>> updateCartItem({
    required String cartItemId,
    required int quantity,
  });

  /// Remove an item from cart
  /// Requirements: 6.3
  Future<Either<Failure, void>> removeCartItem(String cartItemId);

  /// Clear all cart items for a user
  /// Requirements: 7.2
  Future<Either<Failure, void>> clearCart(String userId);

  /// Calculate cart total
  /// Requirements: 6.2
  Future<Either<Failure, double>> getCartTotal(String userId);
}

/// Concrete implementation of cart repository using Supabase
/// Handles cart operations with product joins and total calculation
class CartRepository implements ICartRepository {
  final SupabaseConfig _supabaseConfig;

  CartRepository({SupabaseConfig? supabaseConfig})
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  @override
  Future<Either<Failure, List<CartItem>>> getCartItems(String userId) async {
    try {
      final response = await _supabaseConfig.from('cart_items').select('''
        id,
        user_id,
        product_id,
        quantity,
        created_at,
        products!inner(
          name,
          base_price,
          product_images(url, is_primary)
        )
      ''').eq('user_id', userId);

      final items = (response as List).map((json) {
        final product = json['products'];
        final images = product['product_images'] as List?;
        final imageUrl = images?.isNotEmpty == true
            ? images!.first['url'] as String?
            : null;

        return CartItem(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          productId: json['product_id'] as String,
          productName: product['name'] as String,
          quantity: json['quantity'] as int,
          unitPrice: (product['base_price'] as num).toDouble(),
          imageUrl: imageUrl,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();

      return Right(items);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartItem>> addCartItem({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      // Validate quantity
      if (quantity <= 0) {
        return const Left(ValidationFailure('Quantity must be greater than 0'));
      }

      // Check if product exists and has sufficient stock
      final productResponse = await _supabaseConfig
          .from('products')
          .select('name, base_price, stock_quantity')
          .eq('id', productId)
          .single();

      final stockQuantity = productResponse['stock_quantity'] as int;
      if (stockQuantity < quantity) {
        return const Left(ValidationFailure('Insufficient stock'));
      }

      // Check if item already exists in cart
      final existingItems = await _supabaseConfig
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId);

      if (existingItems.isNotEmpty) {
        // Update existing item
        final existingItem = existingItems.first;
        final newQuantity = (existingItem['quantity'] as int) + quantity;
        
        return updateCartItem(
          cartItemId: existingItem['id'] as String,
          quantity: newQuantity,
        );
      }

      // Create new cart item
      final cartItemData = {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseConfig
          .from('cart_items')
          .insert(cartItemData)
          .select()
          .single();

      final cartItem = CartItem(
        id: response['id'] as String,
        userId: userId,
        productId: productId,
        productName: productResponse['name'] as String,
        quantity: quantity,
        unitPrice: (productResponse['base_price'] as num).toDouble(),
        createdAt: DateTime.parse(response['created_at'] as String),
      );

      return Right(cartItem);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Left(NotFoundFailure('Product not found'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartItem>> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      // Validate quantity
      if (quantity <= 0) {
        return const Left(ValidationFailure('Quantity must be greater than 0'));
      }

      // Fetch cart item to get product ID
      final cartItem = await _supabaseConfig
          .from('cart_items')
          .select('product_id')
          .eq('id', cartItemId)
          .single();

      final productId = cartItem['product_id'] as String;

      // Check product stock
      final productResponse = await _supabaseConfig
          .from('products')
          .select('name, base_price, stock_quantity')
          .eq('id', productId)
          .single();

      final stockQuantity = productResponse['stock_quantity'] as int;
      if (stockQuantity < quantity) {
        return const Left(ValidationFailure('Insufficient stock'));
      }

      // Update cart item
      final response = await _supabaseConfig
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('id', cartItemId)
          .select()
          .single();

      final updatedItem = CartItem(
        id: response['id'] as String,
        userId: response['user_id'] as String,
        productId: productId,
        productName: productResponse['name'] as String,
        quantity: quantity,
        unitPrice: (productResponse['base_price'] as num).toDouble(),
        createdAt: DateTime.parse(response['created_at'] as String),
      );

      return Right(updatedItem);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Left(NotFoundFailure('Cart item not found'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeCartItem(String cartItemId) async {
    try {
      await _supabaseConfig.from('cart_items').delete().eq('id', cartItemId);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCart(String userId) async {
    try {
      await _supabaseConfig.from('cart_items').delete().eq('user_id', userId);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getCartTotal(String userId) async {
    try {
      final itemsResult = await getCartItems(userId);
      
      return itemsResult.fold(
        (failure) => Left(failure),
        (items) {
          final total = items.fold<double>(
            0.0,
            (sum, item) => sum + item.total,
          );
          return Right(total);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
