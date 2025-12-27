import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/core/config/supabase_config.dart';
import 'package:vendora/models/review.dart';

abstract class IReviewRepository {
  Future<Either<Failure, List<Review>>> getProductReviews(String productId);
  Future<Either<Failure, Review>> submitReview(Review review);

  // Return orderId if reviewable, null otherwise
  Future<Either<Failure, String?>> getReviewableOrderId(String userId, String productId);
  Future<Either<Failure, Review>> replyToReview(String reviewId, String reply);
}

class ReviewRepository implements IReviewRepository {
  final SupabaseConfig _supabaseConfig;

  ReviewRepository({SupabaseConfig? supabaseConfig}) 
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  @override
  Future<Either<Failure, List<Review>>> getProductReviews(String productId) async {
    try {
      final response = await _supabaseConfig.client
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      final reviews = (response as List)
          .map((item) => Review.fromJson(item))
          .toList();
      
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review>> submitReview(Review review) async {
    try {
      final response = await _supabaseConfig.client
          .from('reviews')
          .insert(review.toJson()
            ..remove('id')
            ..remove('created_at')
          )
          .select()
          .single();

      return Right(Review.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getReviewableOrderId(String userId, String productId) async {
    try {
      // Check for delivered order item
      final response = await _supabaseConfig.client
          .from('orders')
          .select('id, order_items!inner(product_id)')
          .eq('user_id', userId)
          .eq('status', 'delivered')
          .eq('order_items.product_id', productId)
          .limit(1);

      final list = response as List;
      if (list.isEmpty) {
        return const Right(null);
      }
      
      return Right(list.first['id'] as String);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review>> replyToReview(String reviewId, String reply) async {
    try {
      final response = await _supabaseConfig.client
          .from('reviews')
          .update({
            'seller_reply': reply,
          })
          .eq('id', reviewId)
          .select()
          .single();

      return Right(Review.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
