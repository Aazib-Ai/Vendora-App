import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/order.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/data/repositories/order_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/seller_orders_provider.dart';
import '../widgets/seller_order_card.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access auth provider to get current user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Guard clause if user is not logged in
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view orders")),
      );
    }

    // Initialize provider with dependencies
    return ChangeNotifierProvider(
      create: (_) => SellerOrdersProvider(
        orderRepository: context.read<OrderRepository>(),
        sellerId: user.id,
      )..fetchOrders(),
      child: const _SellerOrdersContent(),
    );
  }
}

class _SellerOrdersContent extends StatelessWidget {
  const _SellerOrdersContent();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Orders', style: AppTypography.headingSmall),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Processing'),
              Tab(text: 'Shipped'),
              Tab(text: 'Delivered'),
            ],
          ),
        ),
        body: Consumer<SellerOrdersProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(provider.error!, style: const TextStyle(color: AppColors.error)),
                    SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => provider.fetchOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                _OrdersList(orders: provider.orders),
                _OrdersList(orders: provider.pendingOrders),
                _OrdersList(orders: provider.processingOrders),
                _OrdersList(orders: provider.shippedOrders),
                _OrdersList(orders: provider.deliveredOrders),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;

  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: AppSpacing.md),
            Text(
              'No orders found',
              style: AppTypography.bodyLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SellerOrdersProvider>().fetchOrders(),
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final provider = context.read<SellerOrdersProvider>();
          
          return SellerOrderCard(
            order: order,
            isProcessing: provider.isProcessingAction,
            onAccept: () => _handleAccept(context, order),
            onReject: () => _handleReject(context, order),
            onShip: () => _handleShip(context, order),
          );
        },
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, Order order) async {
    final provider = context.read<SellerOrdersProvider>();
    final success = await provider.updateOrderStatus(
      order.id, 
      OrderStatus.processing
    );
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context, Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<SellerOrdersProvider>();
      final success = await provider.updateOrderStatus(
        order.id, 
        OrderStatus.cancelled
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected')),
        );
      }
    }
  }

  Future<void> _handleShip(BuildContext context, Order order) async {
    final trackingController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Shipped'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the tracking number for this shipment.'),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'e.g. TCS-123456789',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (trackingController.text.isNotEmpty) {
                Navigator.pop(context, trackingController.text);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      final provider = context.read<SellerOrdersProvider>();
      final success = await provider.updateOrderStatus(
        order.id, 
        OrderStatus.shipped,
        trackingNumber: result,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as shipped'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}