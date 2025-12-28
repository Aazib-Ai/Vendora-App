import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../services/cache_service.dart';
import '../../../models/product.dart';

/// Product sort options for querying
enum ProductSortOption {
  priceAsc,
  priceDesc,
  rating,
  newest,
}

/// Abstract interface for product operations
/// Defines contract for product repository implementations
abstract class IProductRepository {
  /// Get paginated list of products with optional filtering and sorting
  /// Requirements: 5.1, 5.2, 5.3, 5.4
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
    ProductSortOption? sortBy,
    bool onlyApproved = true,
    bool onlyActive = true,
  });

  /// Get a single product by ID
  /// Requirements: 5.5
  Future<Either<Failure, Product>> getProductById(String id);

  /// Create a new product (seller only)
  /// Requirements: 4.1
  Future<Either<Failure, Product>> createProduct(Map<String, dynamic> productData);

  /// Update an existing product
  /// Requirements: 4.2
  Future<Either<Failure, Product>> updateProduct(
    String id,
    Map<String, dynamic> updates,
  );

  /// Delete a product
  /// Requirements: 4.3
  Future<Either<Failure, void>> deleteProduct(String id);

  /// Watch seller's products with real-time updates
  /// Requirements: 4.4
  Stream<List<Product>> watchSellerProducts(String sellerId);
}

/// Concrete implementation of product repository using Supabase
/// Handles CRUD operations with pagination, search, and filtering
class ProductRepository implements IProductRepository {
  final SupabaseConfig _supabaseConfig;
  final CacheService _cacheService;

  ProductRepository({
    SupabaseConfig? supabaseConfig,
    CacheService? cacheService,
  })  : _supabaseConfig = supabaseConfig ?? SupabaseConfig(),
        _cacheService = cacheService ?? CacheService();

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
    ProductSortOption? sortBy,
    bool onlyApproved = true,
    bool onlyActive = true,
  }) async {
    try {
      // Check offline status first
      if (await _cacheService.isOffline()) {
        final cachedData = _cacheService.getCachedProducts();
        if (cachedData.isNotEmpty) {
          final products = cachedData
              .map((json) => Product.fromJson(json))
              .toList();
              
          // Basic filtering on cached data if needed
          if (category != null && category.isNotEmpty) {
             // In a real app, we'd implement full local filtering.
             // For now, return what we have if offline.
          }
          return Right(products);
        }
      }

      // Calculate pagination offset
      final offset = (page - 1) * limit;

      // Build query
      dynamic query = _supabaseConfig.from('products').select('''
        *,
        categories(name),
        sellers(business_name),
        product_images(id, product_id, url, is_primary, display_order),
        product_variants(id, product_id, sku, size, color, material, price, stock_quantity, created_at)
      ''');

      // Filter for only approved and active products (for buyer visibility)
      if (onlyApproved) {
        query = query.eq('status', 'approved');
      }
      
      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        query = query.eq('category_id', category);
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case ProductSortOption.priceAsc:
            query = query.order('base_price', ascending: true);
            break;
          case ProductSortOption.priceDesc:
            query = query.order('base_price', ascending: false);
            break;
          case ProductSortOption.rating:
            query = query.order('average_rating', ascending: false);
            break;
          case ProductSortOption.newest:
            query = query.order('created_at', ascending: false);
            break;
        }
      } else {
        // Default sort by newest
        query = query.order('created_at', ascending: false);
      }

      // Apply pagination
      query = query.range(offset, offset + limit - 1);

      final response = await query;
      
      // Cache the results (simple strategy: cache everything fetched)
      // In production, we might only cache the first page or specific categories.
      if (response != null && response is List && response.isNotEmpty) {
        await _cacheService.cacheProducts(List<Map<String, dynamic>>.from(response));
      }

      final products = (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Database Error: ${e.message}\nDetails: ${e.details}\nHint: ${e.hint}'));
    } catch (e) {
      // Fallback to cache on unexpected error, but only if some data exists
      try {
         final cachedData = _cacheService.getCachedProducts();
         if (cachedData.isNotEmpty) {
            final products = cachedData
                .map((json) => Product.fromJson(json))
                .toList();
            return Right(products);
         }
      } catch (_) {}
      
      return Left(ServerFailure('Unexpected Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final response = await _supabaseConfig.from('products').select('''
        *,
        categories(name),
        sellers(business_name),
        product_images(id, product_id, url, is_primary, display_order),
        product_variants(id, product_id, sku, size, color, material, price, stock_quantity, created_at)
      ''').eq('id', id).single();

      final product = Product.fromJson(response);
      return Right(product);
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
  Future<Either<Failure, Product>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      // Extract related data
      final List<Map<String, dynamic>> images = 
          List<Map<String, dynamic>>.from(productData['images'] ?? []);
      final List<Map<String, dynamic>> variants = 
          List<Map<String, dynamic>>.from(productData['variants'] ?? []);
      
      // Remove from main data to prevent schema error
      productData.remove('images');
      productData.remove('variants');

      // Set default values
      productData['status'] = 'pending';
      productData['is_active'] = true;
      productData['average_rating'] = 0.0;
      productData['review_count'] = 0;
      productData['created_at'] = DateTime.now().toIso8601String();

      // 1. Create Product
      final productResponse = await _supabaseConfig
          .from('products')
          .insert(productData)
          .select()
          .single();
      
      final productId = productResponse['id'];

      // 2. Insert Images
      if (images.isNotEmpty) {
        final imagesToInsert = images.map((img) => {
          ...img,
          'product_id': productId,
        }).toList();
        
        await _supabaseConfig.from('product_images').insert(imagesToInsert);
      }

      // 3. Insert Variants
      if (variants.isNotEmpty) {
        final variantsToInsert = variants.map((v) => {
          ...v,
          'product_id': productId,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();

        await _supabaseConfig.from('product_variants').insert(variantsToInsert);
      }

      // 4. Fetch complete product
      return getProductById(productId);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Extract related data
      final List<Map<String, dynamic>>? images = 
          updates.containsKey('images') 
              ? List<Map<String, dynamic>>.from(updates['images']) 
              : null;
      final List<Map<String, dynamic>>? variants = 
           updates.containsKey('variants') 
              ? List<Map<String, dynamic>>.from(updates['variants']) 
              : null;

      updates.remove('images');
      updates.remove('variants');
      
      updates['updated_at'] = DateTime.now().toIso8601String();

      // 1. Update Product
      await _supabaseConfig
          .from('products')
          .update(updates)
          .eq('id', id);

      // 2. Update Images (Replace strategy for simplicity: delete all, insert new)
      // In a real app, we'd diff them to avoid unnecessary re-uploads/deletes, 
      // but here we just manage the DB records.
      if (images != null) {
        await _supabaseConfig.from('product_images').delete().eq('product_id', id);
        
        if (images.isNotEmpty) {
           final imagesToInsert = images.map((img) => {
            ...img,
            'product_id': id,
          }).toList();
          await _supabaseConfig.from('product_images').insert(imagesToInsert);
        }
      }

      // 3. Update Variants (Replace strategy)
      if (variants != null) {
        await _supabaseConfig.from('product_variants').delete().eq('product_id', id);
        
        if (variants.isNotEmpty) {
          final variantsToInsert = variants.map((v) => {
            ...v,
            'product_id': id,
            'created_at': DateTime.now().toIso8601String(),
          }).toList();
          await _supabaseConfig.from('product_variants').insert(variantsToInsert);
        }
      }

      // 4. Fetch complete product
      return getProductById(id);
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
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      // Note: Cascade delete should handle related tables in DB, 
      // but good to clear images storage if we had that logic here.
      // R2 cleanup would ideally happen via Edge Function trigger on DB delete.
      
      await _supabaseConfig.from('products').delete().eq('id', id);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Product>> watchSellerProducts(String sellerId) {
    return _supabaseConfig.from('products').stream(primaryKey: ['id']).eq(
      'seller_id',
      sellerId,
    ).map((data) {
      return data.map((json) => Product.fromJson(json)).toList();
    });
  }


}
