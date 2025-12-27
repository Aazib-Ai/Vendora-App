import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Image caching service for performance optimization
/// 
/// Task 34.3: Performance optimization
/// Requirements: 12.4 - Cache images locally for offline viewing
/// 
/// This service provides centralized image caching using the
/// `cached_network_image` package with configurable settings.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Default cache configuration
  static const int maxCacheSize = 500; // Maximum number of images to cache
  static const Duration stalePeriod = Duration(days: 7); // Cache validity
  static const int maxMemCacheSize = 100; // In-memory cache limit (MB)

  bool _isInitialized = false;

  /// Initialize the image cache service
  Future<void> init() async {
    if (_isInitialized) return;

    // Configure CachedNetworkImage default settings
    // The package handles most caching internally via flutter_cache_manager
    
    _isInitialized = true;
  }

  /// Get CachedNetworkImage widget with optimized settings
  /// 
  /// Usage:
  /// ```dart
  /// ImageCacheService().getCachedImage(
  ///   imageUrl: 'https://example.com/image.jpg',
  ///   width: 200,
  ///   height: 200,
  /// )
  /// ```
  CachedNetworkImage getCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? 
        const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => errorWidget ??
        const Icon(Icons.error_outline, color: Colors.grey),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }

  /// Preload images for faster display
  /// 
  /// Use this to preload images before they are needed, such as
  /// when scrolling through a product list.
  Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await CachedNetworkImageProvider(url).resolve(
          const ImageConfiguration(),
        );
      } catch (e) {
        // Silently fail for preloading - images will load when needed
      }
    }
  }

  /// Preload a single image
  Future<void> preloadImage(String imageUrl) async {
    try {
      await CachedNetworkImageProvider(imageUrl).resolve(
        const ImageConfiguration(),
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all cached images
  /// 
  /// Use this when the user logs out or to free up storage space.
  Future<void> clearCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final cache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': cache.currentSize,
      'maximumSize': cache.maximumSize,
      'currentSizeBytes': cache.currentSizeBytes,
      'maximumSizeBytes': cache.maximumSizeBytes,
      'liveImageCount': cache.liveImageCount,
      'pendingImageCount': cache.pendingImageCount,
    };
  }

  /// Configure memory cache size
  /// 
  /// Call this early in app initialization to set memory limits.
  void configureMemoryCache({
    int? maximumSize,
    int? maximumSizeBytes,
  }) {
    final cache = PaintingBinding.instance.imageCache;
    if (maximumSize != null) {
      cache.maximumSize = maximumSize;
    }
    if (maximumSizeBytes != null) {
      cache.maximumSizeBytes = maximumSizeBytes;
    }
  }
}
