import 'package:flutter/foundation.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/core/data/repositories/order_repository.dart';
import 'package:vendora/models/order.dart';

class AdminOrdersProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;

  AdminOrdersProvider(this._orderRepository);

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _orderRepository.getAllOrders();

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

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection';
    }
    return 'An unexpected error occurred';
  }
}
