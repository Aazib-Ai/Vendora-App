import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/repositories/product_repository.dart';
import 'package:vendora/services/image_upload_service.dart';
import '../../../../models/product.dart';

enum ProductFormStatus { idle, loading, success, error }

class ProductFormProvider extends ChangeNotifier {
  final ProductRepository _productRepository;
  final ImageUploadService _imageUploadService;

  ProductFormProvider({
    required ProductRepository productRepository,
    required ImageUploadService imageUploadService,
  })  : _productRepository = productRepository,
        _imageUploadService = imageUploadService;

  ProductFormStatus _status = ProductFormStatus.idle;
  ProductFormStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Form Data
  List<dynamic> _images = [];
  List<dynamic> get images => _images;

  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> get variants => _variants;

  Map<String, String> _specifications = {};
  Map<String, String> get specifications => _specifications;

  void setImages(List<dynamic> newImages) {
    _images = newImages;
    notifyListeners();
  }

  void setVariants(List<Map<String, dynamic>> newVariants) {
    _variants = newVariants;
    notifyListeners();
  }

  void setSpecifications(Map<String, String> newSpecs) {
    _specifications = newSpecs;
    notifyListeners();
  }

  void reset() {
    _images = [];
    _variants = [];
    _specifications = {};
    _status = ProductFormStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
  
  void initializeForEdit(Product product) {
    // Populate form data from existing product
    // Note: In real app, we need to map ProductImage and ProductVariant models to local state format
    _images = product.images.map((img) => img.url).toList();
    _variants = product.variants.map((v) => {
      'id': v.id,
      'sku': v.sku,
      'size': v.size,
      'color': v.color,
      'material': v.material,
      'price': v.price,
      'stock_quantity': v.stockQuantity,
    }).toList();
    _specifications = Map.from(product.specifications);
    notifyListeners();
  }

  Future<void> saveProduct({
    required String sellerId,
    required String name,
    required String description,
    required String categoryId,
    required double basePrice,
    double? discountPercentage,
    DateTime? discountValidUntil,
    required int stockQuantity,
    String? productId, // If null, it's a create op
  }) async {
    _status = ProductFormStatus.loading;
    notifyListeners();

    try {
      // 1. Upload new images
      final List<Map<String, dynamic>> processedImages = [];
      
      for (int i = 0; i < _images.length; i++) {
        final img = _images[i];
        String url = '';
        
        if (img is File) {
           final result = await _imageUploadService.uploadImage(
             file: img, 
             bucket: 'products',
             path: '$sellerId/products',
           );
           
           result.fold(
             (failure) => throw Exception(failure.message),
             (uploadUrl) => url = uploadUrl,
           );
        } else if (img is String) {
          url = img;
        }
        
        processedImages.add({
          'url': url,
          'display_order': i,
          'is_primary': i == 0,
        });
      }

      // 2. Prepare Product Data
      final productData = {
        'seller_id': sellerId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'base_price': basePrice,
        'discount_percentage': discountPercentage,
        'discount_valid_until': discountValidUntil?.toIso8601String(),
        'stock_quantity': stockQuantity,
        'specifications': _specifications,
        'is_active': true,
        // Relations will be handled by repo
        'images': processedImages,
        'variants': _variants,
      };

      Either<Failure, Product> result;
      
      if (productId != null) {
        result = await _productRepository.updateProduct(productId, productData);
      } else {
        result = await _productRepository.createProduct(productData);
      }

      result.fold(
        (failure) {
          _status = ProductFormStatus.error;
          _errorMessage = failure.message;
        },
        (product) {
          _status = ProductFormStatus.success;
        },
      );
    } catch (e) {
      _status = ProductFormStatus.error;
      _errorMessage = e.toString();
    }
    
    notifyListeners();
  }
}
