import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _productBoxName = 'products_cache';
  
  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_productBoxName);
  }

  /// Check if device is offline
  Future<bool> isOffline() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult.contains(ConnectivityResult.none);
  }

  /// Cache products as JSON strings
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final box = Hive.box(_productBoxName);
    // Clear existing cache for simplicity or manage merging strategy
    await box.clear();
    
    final Map<String, String> data = {};
    for (var product in products) {
      if (product['id'] != null) {
        data[product['id']] = jsonEncode(product);
      }
    }
    await box.putAll(data);
  }

  /// Get cached products
  List<Map<String, dynamic>> getCachedProducts() {
    final box = Hive.box(_productBoxName);
    final List<Map<String, dynamic>> products = [];
    
    for (var key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        products.add(jsonDecode(jsonString));
      }
    }
    
    return products;
  }
}
