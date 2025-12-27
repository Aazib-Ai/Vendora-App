/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Vendora';
  static const String appVersion = '1.0.0';
  
  // Network
  static const int connectionTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int initialRetryDelaySeconds = 1;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Image Upload
  static const int maxImageSizeMB = 10;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const String defaultImageQuality = 'high';
  
  // Commission
  static const double platformCommissionRate = 0.10; // 10%
  
  // Inventory
  static const int lowStockThreshold = 5;
  
  // Dispute Window
  static const int disputeWindowDays = 7;
  
  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // Order Status
  static const List<String> terminalOrderStatuses = ['delivered', 'cancelled'];
  
  // User Roles
  static const String roleBuyer = 'buyer';
  static const String roleSeller = 'seller';
  static const String roleAdmin = 'admin';
  
  // Seller Status
  static const String sellerStatusUnverified = 'unverified';
  static const String sellerStatusActive = 'active';
  static const String sellerStatusRejected = 'rejected';
  
  // Product Status
  static const String productStatusPending = 'pending';
  static const String productStatusApproved = 'approved';
  static const String productStatusRejected = 'rejected';
  
  // Private constructor to prevent instantiation
  AppConstants._();
}
