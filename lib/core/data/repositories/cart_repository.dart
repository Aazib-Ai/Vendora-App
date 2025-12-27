import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../../models/cart_item_model.dart';

/// Abstract interface for cart operations
abstract class ICartRepository {
  Future<Either<Failure, List<CartItem>>> getCartItems(String userId);
  Future<Either<Failure, CartItem>> addCartItem({
    required String userId,
    required String productId,
    required int quantity,
  });
  Future<Either<Failure, CartItem>> updateCartItem({
    required String cartItemId,
    required int quantity,
  });
  Future<Either<Failure, void>> removeCartItem(String cartItemId);
  Future<Either<Failure, void>> clearCart(String userId);
  Future<Either<Failure, double>> getCartTotal(String userId);
}

/// Concrete implementation of cart repository using Supabase
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
          seller_id,
          product_images(url, is_primary)
        )
      ''').eq('user_id', userId);

      final items = (response as List).map((json) {
        final product = json['products'];
        final images = product['product_images'] as List?;
        final imageUrl = images?.isNotEmpty == true
            ? images!.first['url'] as String?
            : null;

        // Note: seller_id is inside products, but CartItem.fromJson handles it cleanly usually
        // But here we reconstruct manually to pass flat structure or pass proper JSON.
        // Let's pass the fetched JSON to CartItem.fromJson.
        // Wait, the JSON structure here is nested: { ..., products: { ... } }
        // My updated CartItem.fromJson HANDLES this nested structure.
        return CartItem.fromJson(json as Map<String, dynamic>);
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
      if (quantity <= 0) {
        return const Left(ValidationFailure('Quantity must be greater than 0'));
      }

      final productResponse = await _supabaseConfig
          .from('products')
          .select('name, base_price, stock_quantity, seller_id')
          .eq('id', productId)
          .single();

      final stockQuantity = productResponse['stock_quantity'] as int;
      if (stockQuantity < quantity) {
        return const Left(ValidationFailure('Insufficient stock'));
      }
      
      final sellerId = productResponse['seller_id'] as String;

      final existingItems = await _supabaseConfig
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId);

      if (existingItems.isNotEmpty) {
        final existingItem = existingItems.first;
        final newQuantity = (existingItem['quantity'] as int) + quantity;
        
        return updateCartItem(
          cartItemId: existingItem['id'] as String,
          quantity: newQuantity,
        );
      }

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
        sellerId: sellerId,
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
      if (quantity <= 0) {
        return const Left(ValidationFailure('Quantity must be greater than 0'));
      }

      final cartItem = await _supabaseConfig
          .from('cart_items')
          .select('product_id')
          .eq('id', cartItemId)
          .single();

      final productId = cartItem['product_id'] as String;

      final productResponse = await _supabaseConfig
          .from('products')
          .select('name, base_price, stock_quantity, seller_id')
          .eq('id', productId)
          .single();

      final stockQuantity = productResponse['stock_quantity'] as int;
      if (stockQuantity < quantity) {
        return const Left(ValidationFailure('Insufficient stock'));
      }

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
        sellerId: productResponse['seller_id'] as String,
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
