import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';
import 'package:vendora/core/data/repositories/order_repository.dart';
import 'package:vendora/features/seller/data/models/seller_stats.dart';
import 'package:vendora/features/seller/presentation/widgets/stats_card.dart';
import 'package:vendora/features/seller/presentation/widgets/dashboard_chart.dart';
import '../../../../models/order.dart';
import 'seller_profile_screen.dart';
import 'seller_reviews_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _currentIndex = 2; // Dashboard remains the middle tab (index 2)
  late Future<SellerStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      _statsFuture = context.read<OrderRepository>().getSellerStats(userId).then((result) {
        return result.fold(
          (failure) => throw Exception(failure.message),
          (stats) => stats,
        );
      });
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.sellerOrders);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.manageProducts);
        break;
      case 2:
      // Already on dashboard
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.manageCategories);
        break;
      case 4:
        Navigator.push(
          context,
           MaterialPageRoute(builder: (_) => const SellerProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateString = DateFormat('EEEE, d MMMM').format(today);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light neutral background
      body: SafeArea(
        child: FutureBuilder<SellerStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
             if (snapshot.connectionState == ConnectionState.waiting) {
               return const Center(child: CircularProgressIndicator());
             }
             
             if (snapshot.hasError) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.error_outline, size: 48, color: Colors.red),
                     const SizedBox(height: 16),
                     Text('Error loading stats: ${snapshot.error}'),
                     const SizedBox(height: 16),
                     TextButton(onPressed: () {
                       setState(() {
                         _loadStats();
                       });
                     }, child: const Text('Retry'))
                   ],
                 ),
               );
             }

             if (!snapshot.hasData) {
               return const Center(child: Text("No data available"));
             }

             final stats = snapshot.data!;

             return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateString,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.sellerNotifications),
                        icon: const Icon(Icons.notifications_outlined, size: 28),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Alert ---
                  if (stats.pendingOrdersCount > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have ${stats.pendingOrdersCount} pending orders to ship!',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.sellerOrders),
                            child: const Text('View'),
                          )
                        ],
                      ),
                    ),

                  // --- Stats Grid ---
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: "Today's Sales",
                          value: '\$${stats.totalSalesToday.toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatsCard(
                          title: "Pending Orders",
                          value: stats.pendingOrdersCount.toString(),
                          icon: Icons.local_shipping_outlined,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // --- Quick Actions ---
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SellerProfileScreen()),
                          ),
                          icon: const Icon(Icons.store),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                             MaterialPageRoute(builder: (_) => const SellerReviewsScreen()),
                          ),
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Reviews'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Chart ---
                  const Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DashboardChart(salesPoints: stats.weeklySales),
                  ),

                  const SizedBox(height: 24),

                  // --- Top Products ---
                  if (stats.topProducts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       const Text(
                          'Top Products',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                           onPressed: () => Navigator.pushNamed(context, AppRoutes.manageProducts),
                           child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.topProducts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = stats.topProducts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[100],
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                            title: Text(
                                product.productName,
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: Text(
                              '${product.count} sold',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],


                  // --- Recent Orders ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.sellerOrders),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (stats.recentOrders.isEmpty)
                     Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: Text("No orders yet")),
                     )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.recentOrders.length,
                      itemBuilder: (context, index) {
                        final order = stats.recentOrders[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(DateFormat('MMM d, y • h:mm a').format(order.createdAt)),
                            trailing: Chip(
                              label: Text(
                                order.status.name.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              backgroundColor: _getStatusColor(order.status),
                              padding: EdgeInsets.zero,
                            ),
                            onTap: () {
                              // Navigate to order details if implemented, or just orders list for now
                               Navigator.pushNamed(context, AppRoutes.sellerOrders);
                            },
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        role: NavigationRole.seller,
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
