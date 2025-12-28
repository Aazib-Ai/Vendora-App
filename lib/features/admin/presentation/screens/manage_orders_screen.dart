import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/admin/presentation/providers/admin_orders_provider.dart';
import 'package:vendora/features/seller/presentation/widgets/seller_order_card.dart';
import 'package:vendora/models/order.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrdersProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AdminOrdersProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchOrders(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.orders.isEmpty) {
            return const Center(
              child: Text('No orders found on the platform'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return SellerOrderCard(
                  order: order,
                  isProcessing: false,
                  // Admin is view-only for orders in this screen for now
                  onAccept: null,
                  onReject: null,
                  onShip: null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
