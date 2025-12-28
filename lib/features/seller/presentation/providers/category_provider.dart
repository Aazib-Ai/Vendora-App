import 'package:flutter/material.dart';
import '../../../../core/data/repositories/category_repository.dart';
import '../../../../models/category_model.dart';

enum CategoryStatus { idle, loading, success, error }

/// Provider for managing category state in seller screens
class CategoryProvider extends ChangeNotifier {
  final ICategoryRepository _categoryRepository;

  CategoryProvider({required ICategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository;

  // State
  List<Category> _categories = [];
  CategoryStatus _status = CategoryStatus.idle;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  CategoryStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == CategoryStatus.loading;

  /// Load categories for a specific seller
  Future<void> loadCategories(String sellerId) async {
    _status = CategoryStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _categoryRepository.getCategories(sellerId);

    result.fold(
      (failure) {
        _status = CategoryStatus.error;
        _error = failure.message;
      },
      (categories) {
        _categories = categories;
        _status = CategoryStatus.success;
      },
    );

    notifyListeners();
  }

  /// Create a new category
  Future<bool> addCategory({
    required String sellerId,
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    _status = CategoryStatus.loading;
    notifyListeners();

    final result = await _categoryRepository.createCategory(
      sellerId: sellerId,
      name: name,
      description: description,
      iconUrl: iconUrl,
    );

    return result.fold(
      (failure) {
        _status = CategoryStatus.error;
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (category) {
        _categories.insert(0, category);
        _status = CategoryStatus.success;
        notifyListeners();
        return true;
      },
    );
  }

  /// Update an existing category
  Future<bool> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    _status = CategoryStatus.loading;
    notifyListeners();

    final result = await _categoryRepository.updateCategory(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
    );

    return result.fold(
      (failure) {
        _status = CategoryStatus.error;
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (updatedCategory) {
        final index = _categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          _categories[index] = updatedCategory;
        }
        _status = CategoryStatus.success;
        notifyListeners();
        return true;
      },
    );
  }

  /// Delete a category
  Future<bool> deleteCategory(String id) async {
    _status = CategoryStatus.loading;
    notifyListeners();

    final result = await _categoryRepository.deleteCategory(id);

    return result.fold(
      (failure) {
        _status = CategoryStatus.error;
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _categories.removeWhere((c) => c.id == id);
        _status = CategoryStatus.success;
        notifyListeners();
        return true;
      },
    );
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
