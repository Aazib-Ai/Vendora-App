import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../../models/category_model.dart';

/// Abstract interface for category operations
abstract class ICategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories(String sellerId);
  Future<Either<Failure, List<Category>>> getAllCategories();
  Future<Either<Failure, Category>> createCategory({
    required String sellerId,
    required String name,
    String? description,
    String? iconUrl,
  });
  Future<Either<Failure, Category>> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
  });
  Future<Either<Failure, void>> deleteCategory(String id);
}

/// Concrete implementation of category repository using Supabase
class CategoryRepository implements ICategoryRepository {
  final SupabaseConfig _supabaseConfig;

  CategoryRepository({SupabaseConfig? supabaseConfig})
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  @override
  Future<Either<Failure, List<Category>>> getCategories(String sellerId) async {
    try {
      // Use count option to get the number of products for each category
      final response = await _supabaseConfig.client
          .from('categories')
          .select('*, products(count)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final categories = (response as List).map((json) {
        // Extract count from the nested response
        // products: [{count: 5}] -> extract 5
        int count = 0;
        if (json['products'] != null) {
           final productsList = json['products'] as List;
           if (productsList.isNotEmpty) {
             count = productsList[0]['count'] as int? ?? 0;
           }
        }
        
        // Create new map with override product_count
        final Map<String, dynamic> newJson = Map.from(json);
        newJson['product_count'] = count;
        
        return Category.fromJson(newJson);
      }).toList();

      return Right(categories);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Database error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final response = await _supabaseConfig.client
          .from('categories')
          .select()
          .order('name', ascending: true);

      final categories = (response as List)
          .map((json) => Category.fromJson(json))
          .toList();

      return Right(categories);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Database error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory({
    required String sellerId,
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    try {
      final response = await _supabaseConfig.client
          .from('categories')
          .insert({
            'seller_id': sellerId,
            'name': name,
            'icon_url': iconUrl,
            'product_count': 0,
          })
          .select()
          .single();

      return Right(Category.fromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Database error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    try {
      final response = await _supabaseConfig.client
          .from('categories')
          .update({
            'name': name,
            if (iconUrl != null) 'icon_url': iconUrl,
          })
          .eq('id', id)
          .select()
          .single();

      return Right(Category.fromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Database error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await _supabaseConfig.client
          .from('categories')
          .delete()
          .eq('id', id);

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Database error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
