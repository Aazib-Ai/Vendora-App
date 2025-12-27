import 'package:dartz/dartz.dart';
import 'package:vendora/core/data/repositories/notification_repository.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/models/notification.dart';
import 'package:vendora/models/order.dart';

/// Service for creating notifications for various system events
/// Provides high-level methods with event-specific notification construction
class NotificationService {
  final INotificationRepository _notificationRepository;

  NotificationService({
    required INotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository;

  /// Notify buyer when their order status changes
  /// Requirement: 7.9, 14.1
  Future<Either<Failure, void>> notifyOrderStatusChange({
    required String userId,
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    final String title;
    final String body;

    switch (newStatus) {
      case OrderStatus.processing:
        title = 'Order Accepted';
        body = 'Your order has been accepted and is being processed';
        break;
      case OrderStatus.shipped:
        title = 'Order Shipped';
        body = 'Your order is on its way!';
        break;
      case OrderStatus.delivered:
        title = 'Order Delivered';
        body = 'Your order has been delivered. Enjoy your purchase!';
        break;
      case OrderStatus.cancelled:
        title = 'Order Cancelled';
        body = 'Your order has been cancelled';
        break;
      case OrderStatus.pending:
        title = 'Order Placed';
        body = 'Your order has been placed successfully';
        break;
    }

    return _notificationRepository.createNotification(
      userId: userId,
      type: NotificationType.orderStatusUpdate,
      title: title,
      body: body,
      data: {
        'order_id': orderId,
        'status': newStatus.name,
      },
    );
  }

  /// Notify seller when their product is approved by admin
  Future<Either<Failure, void>> notifyProductApproval({
    required String sellerId,
    required String productId,
    required String productName,
  }) async {
    return _notificationRepository.createNotification(
      userId: sellerId,
      type: NotificationType.productApproval,
      title: 'Product Approved',
      body: 'Your product "$productName" has been approved and is now visible to buyers',
      data: {
        'product_id': productId,
        'product_name': productName,
      },
    );
  }

  /// Notify seller when their product is rejected by admin
  Future<Either<Failure, void>> notifyProductRejection({
    required String sellerId,
    required String productId,
    required String productName,
    String? reason,
  }) async {
    final body = reason != null
        ? 'Your product "$productName" was rejected. Reason: $reason'
        : 'Your product "$productName" was rejected';

    return _notificationRepository.createNotification(
      userId: sellerId,
      type: NotificationType.productApproval,
      title: 'Product Rejected',
      body: body,
      data: {
        'product_id': productId,
        'product_name': productName,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Notify seller when their product is hidden by admin
  Future<Either<Failure, void>> notifyProductHidden({
    required String sellerId,
    required String productId,
    required String productName,
  }) async {
    return _notificationRepository.createNotification(
      userId: sellerId,
      type: NotificationType.productApproval,
      title: 'Product Hidden',
      body: 'Your product "$productName" has been hidden by the admin',
      data: {
        'product_id': productId,
        'product_name': productName,
      },
    );
  }

  /// Notify seller (user) when their seller account is approved
  Future<Either<Failure, void>> notifySellerApproval({
    required String userId,
  }) async {
    return _notificationRepository.createNotification(
      userId: userId,
      type: NotificationType.sellerApproval,
      title: 'Seller Account Approved',
      body: 'Congratulations! Your seller account has been approved. You can now start listing products.',
      data: {},
    );
  }

  /// Notify seller (user) when their seller account is rejected
  Future<Either<Failure, void>> notifySellerRejection({
    required String userId,
    required String reason,
  }) async {
    return _notificationRepository.createNotification(
      userId: userId,
      type: NotificationType.sellerApproval,
      title: 'Seller Account Rejected',
      body: 'Your seller application was rejected. Reason: $reason',
      data: {
        'reason': reason,
      },
    );
  }

  /// Notify user about dispute updates
  Future<Either<Failure, void>> notifyDisputeUpdate({
    required String userId,
    required String disputeId,
    required String message,
  }) async {
    return _notificationRepository.createNotification(
      userId: userId,
      type: NotificationType.disputeUpdate,
      title: 'Dispute Update',
      body: message,
      data: {
        'dispute_id': disputeId,
      },
    );
  }
}
