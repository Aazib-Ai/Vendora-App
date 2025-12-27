import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache service for offline support and query optimization
/// 
/// Task 34.3: Performance optimization
/// - Optimize database queries with result caching
/// - Implement query result caching with TTL
/// 
/// Requirements: 12.1, 12.2, 12.3
class CacheService {
  static const String _productBoxName = 'products_cache';
  static const String _queryBoxName = 'query_cache';
  
  /// Default TTL for cached queries (5 minutes)
  static const Duration defaultTTL = Duration(minutes: 5);
  
  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_productBoxName);
    await Hive.openBox(_queryBoxName);
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

  // ============================================
  // Query Result Caching with TTL
  // ============================================

  /// Cache a query result with TTL
  /// 
  /// [key] - Unique key for the query (e.g., 'products_electronics_page1')
  /// [data] - The query result to cache
  /// [ttl] - Time-to-live for the cache entry
  Future<void> cacheQueryResult(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = defaultTTL,
  }) async {
    final box = Hive.box(_queryBoxName);
    final cacheEntry = {
      'data': data,
      'expiresAt': DateTime.now().add(ttl).toIso8601String(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await box.put(key, jsonEncode(cacheEntry));
  }

  /// Get a cached query result if still valid
  /// 
  /// Returns null if cache miss or expired
  Map<String, dynamic>? getCachedQueryResult(String key) {
    final box = Hive.box(_queryBoxName);
    final cached = box.get(key);
    
    if (cached == null) return null;
    
    try {
      final entry = jsonDecode(cached) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(entry['expiresAt'] as String);
      
      if (DateTime.now().isAfter(expiresAt)) {
        // Cache expired, remove it
        box.delete(key);
        return null;
      }
      
      return entry['data'] as Map<String, dynamic>;
    } catch (e) {
      // Invalid cache entry
      box.delete(key);
      return null;
    }
  }

  /// Generate a cache key for a query
  /// 
  /// Example: generateQueryKey('products', {'category': 'electronics', 'page': 1})
  /// Returns: 'products_category:electronics_page:1'
  String generateQueryKey(String table, Map<String, dynamic> params) {
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final paramString = sortedParams
        .map((e) => '${e.key}:${e.value}')
        .join('_');
    
    return '${table}_$paramString';
  }

  /// Invalidate all cached queries for a specific table
  Future<void> invalidateTable(String table) async {
    final box = Hive.box(_queryBoxName);
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      if (key.toString().startsWith('${table}_')) {
        keysToDelete.add(key);
      }
    }
    
    for (var key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Clear all query cache
  Future<void> clearQueryCache() async {
    final box = Hive.box(_queryBoxName);
    await box.clear();
  }

  /// Clean up expired cache entries
  Future<int> cleanupExpiredCache() async {
    final box = Hive.box(_queryBoxName);
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final cached = box.get(key);
      if (cached != null) {
        try {
          final entry = jsonDecode(cached) as Map<String, dynamic>;
          final expiresAt = DateTime.parse(entry['expiresAt'] as String);
          if (DateTime.now().isAfter(expiresAt)) {
            keysToDelete.add(key);
          }
        } catch (e) {
          keysToDelete.add(key);
        }
      }
    }
    
    for (var key in keysToDelete) {
      await box.delete(key);
    }
    
    return keysToDelete.length;
  }

  // ============================================
  // Batch Query Helpers
  // ============================================

  /// Cache multiple items efficiently
  /// 
  /// Use for batch operations to reduce Hive write operations.
  Future<void> batchCacheItems(
    String table,
    List<Map<String, dynamic>> items,
    String idField,
  ) async {
    final box = Hive.box(_queryBoxName);
    final Map<String, String> data = {};
    
    for (var item in items) {
      final id = item[idField]?.toString();
      if (id != null) {
        final key = '${table}_id:$id';
        final entry = {
          'data': item,
          'expiresAt': DateTime.now().add(defaultTTL).toIso8601String(),
          'cachedAt': DateTime.now().toIso8601String(),
        };
        data[key] = jsonEncode(entry);
      }
    }
    
    await box.putAll(data);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final productBox = Hive.box(_productBoxName);
    final queryBox = Hive.box(_queryBoxName);
    
    return {
      'productCacheSize': productBox.length,
      'queryCacheSize': queryBox.length,
      'totalEntries': productBox.length + queryBox.length,
    };
  }
}

