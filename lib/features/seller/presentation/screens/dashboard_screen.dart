import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';
import 'package:vendora/core/data/repositories/order_repository.dart';
import 'package:vendora/core/data/repositories/seller_repository.dart';
import 'package:vendora/features/seller/data/models/seller_stats.dart';
import 'package:vendora/features/seller/presentation/widgets/stats_card.dart';
import 'package:vendora/features/seller/presentation/widgets/dashboard_chart.dart';
import '../../../../models/order.dart';
import 'seller_profile_screen.dart';
import '../providers/seller_dashboard_provider.dart';
import 'seller_reviews_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _currentIndex = 2; // Dashboard remains the middle tab (index 2)


  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid provider update during build if logic is complex, 
    // though initState is usually fine for read, listen:false.
    // However, since we want to trigger a load that notifies listeners, it's safer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  void _loadStats() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<SellerDashboardProvider>().loadDashboardData(userId);
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
        child: Consumer<SellerDashboardProvider>(
          builder: (context, provider, child) {
             if (provider.isLoading) {
               return const Center(child: CircularProgressIndicator());
             }
             
             if (provider.error != null) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.error_outline, size: 48, color: Colors.red),
                     const SizedBox(height: 16),
                     Text('Error loading stats: ${provider.error}'),
                     const SizedBox(height: 16),
                     TextButton(onPressed: _loadStats, child: const Text('Retry'))
                   ],
                 ),
               );
             }

             if (provider.stats == null) {
               return const Center(child: Text("No data available"));
             }

             final stats = provider.stats!;

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
                  if (stats.ordersPending > 0)
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
                              'You have ${stats.ordersPending} pending orders to ship!',
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
                          value: '\$${stats.salesToday.toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatsCard(
                          title: "Pending Orders",
                          value: stats.ordersPending.toString(),
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
                    child: DashboardChart(salesPoints: _mapWeeklySales(stats.weeklySales)),
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
                              '${product.salesCount} sold',
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
                  // recentOrders is not in SellerStats from SellerRepository yet!
                  // It was in the Simple model. We need to handle this or remove it.
                  // For now, let's remove the recent orders section or show "Check Orders Tab".
                  // Actually the user wants to see orders.
                  // Since SellerRepository SellerStats doesn't have recentOrders, 
                  // we should probably just show a button or remove this section.
                  // Wait, let's just make it a simple card that says "View Orders".
                     Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                            child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.sellerOrders),
                                child: const Text("View Recent Orders")
                            )
                        ),
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

  // Helper to map list of doubles to SalesPoint for the chart
  List<SalesPoint> _mapWeeklySales(List<double> weeklySales) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      List<SalesPoint> points = [];
      // weeklySales index 0 is 7 days ago?
      // SellerRepository.getSellerStats logic:
      // index 6 is Today (diff 0), Index 0 is 7 days ago.
      
      for (int i = 0; i < weeklySales.length; i++) {
          // If index 6 is today, then index 0 is today - 6 days.
          // Wait, SellerRepository logic:
          // int index = 6 - diffDays;
          // diffDays 0 (today) -> index 6.
          // diffDays 6 (6 days ago) -> index 0.
          
          // So index 0 is oldest.
          final date = today.subtract(Duration(days: 6 - i));
          points.add(SalesPoint(date, weeklySales[i]));
      }
      return points;
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
