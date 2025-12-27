import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/models/wishlist_item.dart';

abstract class IWishlistRepository {
  Future<Either<Failure, List<WishlistItem>>> getWishlist(String userId);
  Future<Either<Failure, WishlistItem>> addToWishlist(String userId, String productId, double price);
  Future<Either<Failure, void>> removeFromWishlist(String userId, String productId);
  Future<Either<Failure, bool>> isInWishlist(String userId, String productId);
  Stream<List<WishlistItem>> watchWishlist(String userId);
}

class WishlistRepository implements IWishlistRepository {
  final SupabaseConfig _supabaseConfig;

  WishlistRepository({SupabaseConfig? supabaseConfig}) 
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  @override
  Future<Either<Failure, List<WishlistItem>>> getWishlist(String userId) async {
    try {
      final response = await _supabaseConfig.client
          .from('wishlist_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final wishlist = (response as List)
          .map((item) => WishlistItem.fromJson(item))
          .toList();
      
      return Right(wishlist);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WishlistItem>> addToWishlist(String userId, String productId, double price) async {
    try {
      final response = await _supabaseConfig.client
          .from('wishlist_items')
          .insert({
            'user_id': userId,
            'product_id': productId,
            'price_at_add': price,
          })
          .select()
          .single();

      return Right(WishlistItem.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromWishlist(String userId, String productId) async {
    try {
      await _supabaseConfig.client
          .from('wishlist_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isInWishlist(String userId, String productId) async {
    try {
      final response = await _supabaseConfig.client
          .from('wishlist_items')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return Right(response != null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<WishlistItem>> watchWishlist(String userId) {
    return _supabaseConfig.client
        .from('wishlist_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => WishlistItem.fromJson(json)).toList());
  }
}
