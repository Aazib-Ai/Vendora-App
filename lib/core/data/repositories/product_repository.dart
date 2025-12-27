import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../services/cache_service.dart';
import '../../../models/product_model.dart';

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
  }) async {
    try {
      // Check offline status first
      if (await _cacheService.isOffline()) {
        final cachedData = _cacheService.getCachedProducts();
        if (cachedData.isNotEmpty) {
          final products = cachedData
              .map((json) => _parseProduct(json))
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
        product_images(url, is_primary, display_order),
        product_variants(id, sku, size, color, material, price, stock_quantity)
      ''');

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
          .map((json) => _parseProduct(json as Map<String, dynamic>))
          .toList();

      return Right(products);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      // Fallback to cache on error
      try {
         final cachedData = _cacheService.getCachedProducts();
         if (cachedData.isNotEmpty) {
            final products = cachedData
                .map((json) => _parseProduct(json))
                .toList();
            return Right(products);
         }
      } catch (_) {}
      
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final response = await _supabaseConfig.from('products').select('''
        *,
        product_images(url, is_primary, display_order),
        product_variants(id, sku, size, color, material, price, stock_quantity)
      ''').eq('id', id).single();

      final product = _parseProduct(response);
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
      // Set default values
      productData['status'] = 'pending';
      productData['is_active'] = true;
      productData['average_rating'] = 0.0;
      productData['review_count'] = 0;
      productData['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseConfig
          .from('products')
          .insert(productData)
          .select()
          .single();

      final product = _parseProduct(response);
      return Right(product);
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
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseConfig
          .from('products')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      final product = _parseProduct(response);
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
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
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
      return data.map((json) => _parseProduct(json)).toList();
    });
  }

  /// Helper method to parse product data from JSON
  Product _parseProduct(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category_id'] as String? ?? '',
      description: json['description'] as String,
      price: (json['base_price'] as num).toDouble(),
      imageUrl: _getMainImageUrl(json['product_images']),
      rating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      specifications: _parseSpecifications(json['specifications']),
      sellerId: json['seller_id'] as String,
      status: json['status'] as String? ?? 'approved',
    );
  }

  /// Extract main image URL from product images
  String _getMainImageUrl(dynamic images) {
    if (images == null || images is! List || images.isEmpty) {
      return '';
    }

    // Find primary image or use first one
    final primaryImage = (images as List).firstWhere(
      (img) => img['is_primary'] == true,
      orElse: () => images.first,
    );

    return primaryImage['url'] as String? ?? '';
  }

  /// Parse specifications from JSONB to Map<String, String>
  Map<String, String> _parseSpecifications(dynamic specs) {
    if (specs == null || specs is! Map) {
      return {};
    }

    return (specs as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }
}
