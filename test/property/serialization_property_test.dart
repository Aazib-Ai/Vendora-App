import 'package:flutter_test/flutter_test.dart';
import 'package:vendora/models/user_entity.dart';
import 'package:vendora/models/product.dart';
import 'package:vendora/models/address.dart';
import 'package:vendora/models/order.dart';
import 'package:vendora/models/review.dart';
import 'package:vendora/models/wishlist_item.dart';
import 'package:vendora/models/notification.dart';
import 'package:vendora/models/dispute.dart';

/// **Feature: vendora-backend-enhancement, Property 1: Model Serialization Round-Trip**
/// **Validates: Requirements 11.1, 11.2, 11.3**
/// 
/// This test validates that all model objects can be serialized to JSON
/// and deserialized back without losing data (round-trip consistency).
void main() {
  group('Model Serialization Round-Trip', () {
    test('UserEntity serialization round-trip preserves all fields', () {
      // Arrange
      final user = UserEntity(
        id: 'test-user-id-123',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+1234567890',
        role: UserRole.buyer,
        profileImageUrl: 'https://example.com/profile.jpg',
        isActive: true,
        createdAt: DateTime.parse('2025-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2025-01-16T14:20:00Z'),
      );

      // Act
      final json = user.toJson();
      final restored = UserEntity.fromJson(json);

      // Assert
      expect(restored.id, equals(user.id));
      expect(restored.email, equals(user.email));
      expect(restored.name, equals(user.name));
      expect(restored.phone, equals(user.phone));
      expect(restored.role, equals(user.role));
      expect(restored.profileImageUrl, equals(user.profileImageUrl));
      expect(restored.isActive, equals(user.isActive));
      expect(restored.createdAt.toIso8601String(),
          equals(user.createdAt.toIso8601String()));
      expect(restored.updatedAt?.toIso8601String(),
          equals(user.updatedAt?.toIso8601String()));
    });

    test('Product serialization round-trip preserves all fields', () {
      // Arrange
      final product = Product(
        id: 'prod-123',
        sellerId: 'seller-456',
        categoryId: 'cat-789',
        name: 'Test Product',
        description: 'A test product description',
        basePrice: 99.99,
        discountPercentage: 10.0,
        discountValidUntil: DateTime.parse('2025-12-31T23:59:59Z'),
        stockQuantity: 50,
        specifications: {'color': 'blue', 'size': 'M'},
        status: ProductStatus.approved,
        isActive: true,
        averageRating: 4.5,
        reviewCount: 10,
        createdAt: DateTime.parse('2025-01-10T08:00:00Z'),
        updatedAt: DateTime.parse('2025-01-11T12:00:00Z'),
      );

      // Act
      final json = product.toJson();
      final restored = Product.fromJson(json);

      // Assert
      expect(restored.id, equals(product.id));
      expect(restored.sellerId, equals(product.sellerId));
      expect(restored.categoryId, equals(product.categoryId));
      expect(restored.name, equals(product.name));
      expect(restored.description, equals(product.description));
      expect(restored.basePrice, equals(product.basePrice));
      expect(restored.discountPercentage, equals(product.discountPercentage));
      expect(restored.discountValidUntil?.toIso8601String(),
          equals(product.discountValidUntil?.toIso8601String()));
      expect(restored.stockQuantity, equals(product.stockQuantity));
      expect(restored.specifications, equals(product.specifications));
      expect(restored.status, equals(product.status));
      expect(restored.isActive, equals(product.isActive));
      expect(restored.averageRating, equals(product.averageRating));
      expect(restored.reviewCount, equals(product.reviewCount));
      expect(restored.createdAt.toIso8601String(),
          equals(product.createdAt.toIso8601String()));
    });

    test('Order serialization round-trip preserves all fields', () {
      // Arrange
      final order = Order(
        id: 'order-123',
        userId: 'user-456',
        addressId: 'addr-789',
        status: OrderStatus.processing,
        subtotal: 100.0,
        platformCommission: 10.0,
        total: 110.0,
        paymentMethod: 'credit_card',
        trackingNumber: 'TRACK123',
        deliveredAt: DateTime.parse('2025-01-20T15:00:00Z'),
        createdAt: DateTime.parse('2025-01-15T10:00:00Z'),
        updatedAt: DateTime.parse('2025-01-16T11:00:00Z'),
      );

      // Act
      final json = order.toJson();
      final restored = Order.fromJson(json);

      // Assert
      expect(restored.id, equals(order.id));
      expect(restored.userId, equals(order.userId));
      expect(restored.addressId, equals(order.addressId));
      expect(restored.status, equals(order.status));
      expect(restored.subtotal, equals(order.subtotal));
      expect(restored.platformCommission, equals(order.platformCommission));
      expect(restored.total, equals(order.total));
      expect(restored.paymentMethod, equals(order.paymentMethod));
      expect(restored.trackingNumber, equals(order.trackingNumber));
      expect(restored.deliveredAt?.toIso8601String(),
          equals(order.deliveredAt?.toIso8601String()));
      expect(restored.createdAt.toIso8601String(),
          equals(order.createdAt.toIso8601String()));
    });

    test('Address serialization round-trip preserves all fields', () {
      // Arrange
      final address = Address(
        id: 'addr-123',
        userId: 'user-456',
        label: 'Home',
        addressText: '123 Main St, City, Country',
        latitude: 40.7128,
        longitude: -74.0060,
        isDefault: true,
        createdAt: DateTime.parse('2025-01-10T09:00:00Z'),
      );

      // Act
      final json = address.toJson();
      final restored = Address.fromJson(json);

      // Assert
      expect(restored.id, equals(address.id));
      expect(restored.userId, equals(address.userId));
      expect(restored.label, equals(address.label));
      expect(restored.addressText, equals(address.addressText));
      expect(restored.latitude, equals(address.latitude));
      expect(restored.longitude, equals(address.longitude));
      expect(restored.isDefault, equals(address.isDefault));
      expect(restored.createdAt.toIso8601String(),
          equals(address.createdAt.toIso8601String()));
    });

    test('Review serialization round-trip preserves all fields', () {
      // Arrange
      final review = Review(
        id: 'review-123',
        userId: 'user-456',
        productId: 'prod-789',
        orderId: 'order-012',
        rating: 5,
        comment: 'Great product!',
        sellerReply: 'Thank you!',
        createdAt: DateTime.parse('2025-01-18T14:00:00Z'),
      );

      // Act
      final json = review.toJson();
      final restored = Review.fromJson(json);

      // Assert
      expect(restored.id, equals(review.id));
      expect(restored.userId, equals(review.userId));
      expect(restored.productId, equals(review.productId));
      expect(restored.orderId, equals(review.orderId));
      expect(restored.rating, equals(review.rating));
      expect(restored.comment, equals(review.comment));
      expect(restored.sellerReply, equals(review.sellerReply));
      expect(restored.createdAt.toIso8601String(),
          equals(review.createdAt.toIso8601String()));
    });

    test('WishlistItem serialization round-trip preserves all fields', () {
      // Arrange
      final wishlistItem = WishlistItem(
        id: 'wish-123',
        userId: 'user-456',
        productId: 'prod-789',
        priceAtAdd: 79.99,
        createdAt: DateTime.parse('2025-01-12T11:00:00Z'),
      );

      // Act
      final json = wishlistItem.toJson();
      final restored = WishlistItem.fromJson(json);

      // Assert
      expect(restored.id, equals(wishlistItem.id));
      expect(restored.userId, equals(wishlistItem.userId));
      expect(restored.productId, equals(wishlistItem.productId));
      expect(restored.priceAtAdd, equals(wishlistItem.priceAtAdd));
      expect(restored.createdAt.toIso8601String(),
          equals(wishlistItem.createdAt.toIso8601String()));
    });

    test('Notification serialization round-trip preserves all fields', () {
      // Arrange
      final notification = Notification(
        id: 'notif-123',
        userId: 'user-456',
        type: NotificationType.orderStatusUpdate,
        title: 'Order Shipped',
        body: 'Your order has been shipped',
        data: {'orderId': 'order-789'},
        isRead: false,
        createdAt: DateTime.parse('2025-01-17T16:00:00Z'),
      );

      // Act
      final json = notification.toJson();
      final restored = Notification.fromJson(json);

      // Assert
      expect(restored.id, equals(notification.id));
      expect(restored.userId, equals(notification.userId));
      expect(restored.type, equals(notification.type));
      expect(restored.title, equals(notification.title));
      expect(restored.body, equals(notification.body));
      expect(restored.data, equals(notification.data));
      expect(restored.isRead, equals(notification.isRead));
      expect(restored.createdAt.toIso8601String(),
          equals(notification.createdAt.toIso8601String()));
    });

    test('Dispute serialization round-trip preserves all fields', () {
      // Arrange
      final dispute = Dispute(
        id: 'dispute-123',
        orderId: 'order-456',
        buyerId: 'buyer-789',
        sellerId: 'seller-012',
        status: DisputeStatus.underReview,
        reason: 'Product damaged',
        buyerDescription: 'The product arrived damaged',
        buyerEvidence: {'imageUrl': 'https://example.com/damage.jpg'},
        sellerResponse: 'We will investigate',
        sellerEvidence: {},
        adminResolution: null,
        resolvedAt: null,
        createdAt: DateTime.parse('2025-01-19T10:00:00Z'),
      );

      // Act
      final json = dispute.toJson();
      final restored = Dispute.fromJson(json);

      // Assert
      expect(restored.id, equals(dispute.id));
      expect(restored.orderId, equals(dispute.orderId));
      expect(restored.buyerId, equals(dispute.buyerId));
      expect(restored.sellerId, equals(dispute.sellerId));
      expect(restored.status, equals(dispute.status));
      expect(restored.reason, equals(dispute.reason));
      expect(restored.buyerDescription, equals(dispute.buyerDescription));
      expect(restored.buyerEvidence, equals(dispute.buyerEvidence));
      expect(restored.sellerResponse, equals(dispute.sellerResponse));
      expect(restored.adminResolution, equals(dispute.adminResolution));
      expect(restored.createdAt.toIso8601String(),
          equals(dispute.createdAt.toIso8601String()));
    });

    test('ProductImage serialization round-trip preserves all fields', () {
      // Arrange
      final image = ProductImage(
        id: 'img-123',
        productId: 'prod-456',
        url: 'https://example.com/product.jpg',
        displayOrder: 1,
        isPrimary: true,
      );

      // Act
      final json = image.toJson();
      final restored = ProductImage.fromJson(json);

      // Assert
      expect(restored.id, equals(image.id));
      expect(restored.productId, equals(image.productId));
      expect(restored.url, equals(image.url));
      expect(restored.displayOrder, equals(image.displayOrder));
      expect(restored.isPrimary, equals(image.isPrimary));
    });

    test('ProductVariant serialization round-trip preserves all fields', () {
      // Arrange
      final variant = ProductVariant(
        id: 'var-123',
        productId: 'prod-456',
        sku: 'SKU-001',
        size: 'L',
        color: 'Red',
        material: 'Cotton',
        price: 89.99,
        stockQuantity: 25,
        createdAt: DateTime.parse('2025-01-11T10:00:00Z'),
      );

      // Act
      final json = variant.toJson();
      final restored = ProductVariant.fromJson(json);

      // Assert
      expect(restored.id, equals(variant.id));
      expect(restored.productId, equals(variant.productId));
      expect(restored.sku, equals(variant.sku));
      expect(restored.size, equals(variant.size));
      expect(restored.color, equals(variant.color));
      expect(restored.material, equals(variant.material));
      expect(restored.price, equals(variant.price));
      expect(restored.stockQuantity, equals(variant.stockQuantity));
      expect(restored.createdAt.toIso8601String(),
          equals(variant.createdAt.toIso8601String()));
    });

    test('OrderItem serialization round-trip preserves all fields', () {
      // Arrange
      final item = OrderItem(
        id: 'item-123',
        orderId: 'order-456',
        productId: 'prod-789',
        variantId: 'var-012',
        sellerId: 'seller-345',
        productName: 'Test Product',
        variantInfo: 'Size: L, Color: Red',
        quantity: 2,
        unitPrice: 89.99,
        totalPrice: 179.98,
      );

      // Act
      final json = item.toJson();
      final restored = OrderItem.fromJson(json);

      // Assert
      expect(restored.id, equals(item.id));
      expect(restored.orderId, equals(item.orderId));
      expect(restored.productId, equals(item.productId));
      expect(restored.variantId, equals(item.variantId));
      expect(restored.sellerId, equals(item.sellerId));
      expect(restored.productName, equals(item.productName));
      expect(restored.variantInfo, equals(item.variantInfo));
      expect(restored.quantity, equals(item.quantity));
      expect(restored.unitPrice, equals(item.unitPrice));
      expect(restored.totalPrice, equals(item.totalPrice));
    });

    test('OrderStatusHistory serialization round-trip preserves all fields', () {
      // Arrange
      final history = OrderStatusHistory(
        id: 'hist-123',
        orderId: 'order-456',
        status: OrderStatus.shipped,
        note: 'Package picked up by courier',
        createdAt: DateTime.parse('2025-01-18T09:00:00Z'),
      );

      // Act
      final json = history.toJson();
      final restored = OrderStatusHistory.fromJson(json);

      // Assert
      expect(restored.id, equals(history.id));
      expect(restored.orderId, equals(history.orderId));
      expect(restored.status, equals(history.status));
      expect(restored.note, equals(history.note));
      expect(restored.createdAt.toIso8601String(),
          equals(history.createdAt.toIso8601String()));
    });
  });
}
