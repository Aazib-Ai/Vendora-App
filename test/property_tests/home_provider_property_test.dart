import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:vendora/core/data/repositories/product_repository.dart';
import 'package:vendora/features/buyer/presentation/providers/home_provider.dart';
import 'package:vendora/models/product_model.dart';
import 'package:vendora/core/errors/failures.dart';

// Manual Mock for Repository
class MockProductRepository implements IProductRepository {
  List<Product> mockProducts = [];
  bool shouldFail = false;

  @override
  Future<Either<Failure, Product>> createProduct(Map<String, dynamic> productData) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Product>> updateProduct(String id, Map<String, dynamic> updates) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchSellerProducts(String sellerId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
    ProductSortOption? sortBy,
  }) async {
    if (shouldFail) {
      return Left(ServerFailure('Mock Error'));
    }

    var result = List<Product>.from(mockProducts);

    // 1. Filter by Category
    if (category != null) {
      result = result.where((p) => p.category == category).toList();
    }

    // 2. Search
    if (searchQuery != null) {
      result = result.where((p) => p.name.contains(searchQuery)).toList();
    }

    // 3. Sort
    if (sortBy != null) {
      switch (sortBy) {
        case ProductSortOption.priceAsc:
          result.sort((a, b) => a.price.compareTo(b.price));
          break;
        case ProductSortOption.priceDesc:
          result.sort((a, b) => b.price.compareTo(a.price));
          break;
        case ProductSortOption.rating:
          result.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case ProductSortOption.newest:
           // Mock check: Assuming mocked list is already in some order or id
           // For simplicity in property test, we trust the repo does its job,
           // OR we implement the sort logic here to mimic DB.
           // We'll mimic DB sort.
           // Assuming higher ID is newer for this mock
           result.sort((a, b) => b.id.compareTo(a.id)); 
           break;
      }
    }

    // 4. Pagination
    final startIndex = (page - 1) * limit;
    if (startIndex >= result.length) {
      return Right([]);
    }
    final endIndex = startIndex + limit;
    final paged = result.sublist(
      startIndex, 
      endIndex > result.length ? result.length : endIndex
    );

    return Right(paged);
  }
}

void main() {
  late MockProductRepository mockRepo;
  late HomeProvider provider;
  
  // Helper to generate products
  List<Product> generateProducts(int count) {
    return List.generate(count, (index) => Product(
      id: index.toString(),
      name: 'Product $index',
      category: index % 2 == 0 ? 'Shoes' : 'Clothes',
      description: 'Desc',
      price: (index + 1) * 100.0, // 100, 200, 300...
      imageUrl: 'img',
      rating: (index % 5) + 1.0,
      reviewCount: 0,
      sellerId: 's1',
      status: 'approved',
      specifications: {},
    ));
  }

  setUp(() {
    mockRepo = MockProductRepository();
    provider = HomeProvider(productRepository: mockRepo);
  });

  group('HomeProvider Property Tests', () {
    test('Property 5: Category Filter Correctness - All returned products must match selected category', () async {
      // ARRANGEMENT
      mockRepo.mockProducts = generateProducts(50); // Mix of Shoes and Clothes
      
      // ACTION
      provider.setCategory('Shoes');
      await Future.delayed(Duration.zero); // Wait for async

      // ASSERTION
      expect(provider.products.isNotEmpty, true);
      for (final product in provider.products) {
        expect(product.category, 'Shoes', reason: 'Product ${product.name} should be in Shoes category');
      }
    });

    test('Property 6: Product Sort Order Correctness (Price Ascending) - Products must be sorted by price', () async {
      // ARRANGEMENT
      mockRepo.mockProducts = generateProducts(10); // Prices: 100, 200... 1000
      // Shuffle them so they aren't already sorted in the mock list source if we want, 
      // but our mock repo implements the sort logic, so verify the Provider requests it and gets it.
      mockRepo.mockProducts.shuffle();

      // ACTION
      provider.setSortOption(ProductSortOption.priceAsc);
      await Future.delayed(Duration.zero);

      // ASSERTION
      expect(provider.products.isNotEmpty, true);
      for (int i = 0; i < provider.products.length - 1; i++) {
        expect(
          provider.products[i].price, 
          lessThanOrEqualTo(provider.products[i + 1].price),
          reason: 'Product at index $i (${provider.products[i].price}) should be cheaper than ${provider.products[i+1].price}'
        );
      }
    });

    test('Property 6: Product Sort Order Correctness (Price Descending) - Products must be sorted by price descending', () async {
        // ARRANGEMENT
        mockRepo.mockProducts = generateProducts(10);
        mockRepo.mockProducts.shuffle();

        // ACTION
        provider.setSortOption(ProductSortOption.priceDesc);
        await Future.delayed(Duration.zero);

        // ASSERTION
        expect(provider.products.isNotEmpty, true);
        for (int i = 0; i < provider.products.length - 1; i++) {
          expect(
            provider.products[i].price, 
            greaterThanOrEqualTo(provider.products[i + 1].price),
            reason: 'Product at index $i should be more expensive than next'
          );
        }
    });
  });
}
