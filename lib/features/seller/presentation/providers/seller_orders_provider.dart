import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../../../../models/order.dart';
import '../../../../core/data/repositories/order_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../main.dart'; // For accessing global providers/repositories if needed, or better use constructor injection

class SellerOrdersProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;
  final String _sellerId; // In a real app, this comes from AuthProvider

  SellerOrdersProvider({
    required OrderRepository orderRepository,
    required String sellerId,
  })  : _orderRepository = orderRepository,
        _sellerId = sellerId;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _isProcessingAction = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProcessingAction => _isProcessingAction;

  // Filtered lists
  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();
  List<Order> get processingOrders =>
      _orders.where((o) => o.status == OrderStatus.processing).toList();
  List<Order> get shippedOrders =>
      _orders.where((o) => o.status == OrderStatus.shipped).toList();
  List<Order> get deliveredOrders =>
      _orders.where((o) => o.status == OrderStatus.delivered).toList();
  List<Order> get cancelledOrders =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _orderRepository.getSellerOrders(_sellerId);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (orders) {
        _orders = orders;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus, {String? trackingNumber}) async {
    _isProcessingAction = true;
    notifyListeners();

    final result = await _orderRepository.updateOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
      trackingNumber: trackingNumber,
    );

    return result.fold(
      (failure) {
        _isProcessingAction = false;
        // In a real app we might show a snackbar or toast here via a callback or global key
        notifyListeners();
         return false;
      },
      (updatedOrder) {
        // Update local list
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }
        _isProcessingAction = false;
        notifyListeners();
        return true;
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Please check your internet connection';
    } else {
      return 'An unexpected error occurred';
    }
  }
}
