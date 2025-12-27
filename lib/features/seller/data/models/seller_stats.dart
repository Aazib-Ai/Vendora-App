import 'package:equatable/equatable.dart';
import '../../../../models/order.dart';

class SellerStats extends Equatable {
  final double totalSalesToday;
  final int pendingOrdersCount;
  final List<SalesPoint> weeklySales;
  final List<TopProduct> topProducts;
  final List<Order> recentOrders;

  const SellerStats({
    required this.totalSalesToday,
    required this.pendingOrdersCount,
    required this.weeklySales,
    required this.topProducts,
    required this.recentOrders,
  });

  @override
  List<Object> get props => [
        totalSalesToday,
        pendingOrdersCount,
        weeklySales,
        topProducts,
        recentOrders,
      ];
}

class SalesPoint extends Equatable {
  final DateTime date;
  final double amount;

  const SalesPoint(this.date, this.amount);

  @override
  List<Object> get props => [date, amount];
}

class TopProduct extends Equatable {
  final String productName;
  final int count;

  const TopProduct(this.productName, this.count);

  @override
  List<Object> get props => [productName, count];
}
