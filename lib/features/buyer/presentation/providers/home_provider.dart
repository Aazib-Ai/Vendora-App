import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/repositories/product_repository.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../models/product.dart';
import '../../../../models/demo_data.dart'; // fallback/reference

class HomeProvider extends ChangeNotifier {
  final IProductRepository _productRepository;
  final ICategoryRepository? _categoryRepository;

  // State
  List<Product> _products = [];
  List<String> _categories = ['All Items'];
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageSize = 20;

  // Filters & Search
  String _searchQuery = '';
  String _selectedCategory = 'All Items';
  ProductSortOption _sortOption = ProductSortOption.newest;
  Timer? _debounceTimer;

  // Getters
  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  ProductSortOption get sortOption => _sortOption;
  bool get hasMore => _hasMore;

  HomeProvider({
    required IProductRepository productRepository,
    ICategoryRepository? categoryRepository,
  })  : _productRepository = productRepository,
        _categoryRepository = categoryRepository;

  // Initialize
  Future<void> loadInitialData() async {
    _resetPagination();
    await Future.wait([
      _fetchProducts(),
      _fetchCategories(),
    ]);
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _fetchProducts(append: true);
  }

  Future<void> refresh() async {
    _resetPagination();
    await Future.wait([
      _fetchProducts(),
      _fetchCategories(),
    ]);
  }

  Future<void> _fetchCategories() async {
    if (_categoryRepository == null) return;
    
    _isCategoriesLoading = true;
    notifyListeners();

    final result = await _categoryRepository!.getAllCategoryNames();

    result.fold(
      (failure) {
        // Keep default categories on error
        _isCategoriesLoading = false;
        notifyListeners();
      },
      (categoryNames) {
        // Always include 'All Items' first
        _categories = ['All Items', ...categoryNames];
        _isCategoriesLoading = false;
        notifyListeners();
      },
    );
  }

  // Actions
  void setSearchQuery(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        _searchQuery = query;
        _resetPagination();
        _fetchProducts();
        notifyListeners();
      }
    });
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _resetPagination();
      _fetchProducts();
      notifyListeners();
    }
  }

  void setSortOption(ProductSortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      _resetPagination();
      _fetchProducts();
      notifyListeners();
    }
  }

  void _resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _products = [];
    _error = null;
  }

  Future<void> _fetchProducts({bool append = false}) async {
    if (!append) {
      _isLoading = true;
      notifyListeners();
    }

    final result = await _productRepository.getProducts(
      page: _currentPage,
      limit: _pageSize,
      category: _selectedCategory == 'All Items' ? null : _selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      sortBy: _sortOption,
    );

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (newProducts) {
        if (newProducts.length < _pageSize) {
          _hasMore = false;
        }
        
        if (append) {
          _products.addAll(newProducts);
        } else {
          _products = newProducts;
        }
        
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection. Showing cached data.';
    } else if (failure is ServerFailure) {
      return failure.message; // 'Server Error. Please try again later.';
    } else {
      return 'Something went wrong';
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
