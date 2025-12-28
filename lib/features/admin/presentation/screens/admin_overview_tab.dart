import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/features/admin/domain/entities/admin_stats.dart';
import 'package:vendora/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:vendora/features/admin/presentation/screens/manage_products_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_sellers_screen.dart';
import 'package:vendora/features/admin/presentation/screens/seller_kyc_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_users_screen.dart';
import 'package:vendora/features/admin/presentation/widgets/action_alert_card.dart';
import 'package:vendora/features/admin/presentation/widgets/admin_revenue_chart.dart';
import 'package:vendora/features/admin/presentation/widgets/stats_card.dart';

class AdminOverviewTab extends StatefulWidget {
  const AdminOverviewTab({super.key});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  @override
  void initState() {
    super.initState();
    // Load initial stats and subscribe to updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminDashboardProvider>();
      provider.loadStats();
      provider.subscribeToStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Dashboard Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false, // Shell handles navigation
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: Consumer<AdminDashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stats == AdminStats.empty()) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A1A2E),
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.refreshStats,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = provider.stats;

          return RefreshIndicator(
            onRefresh: provider.refreshStats,
            color: const Color(0xFF1A1A2E),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Platform Overview Header
                const Text(
                  'Platform Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 16),

                // Statistics Cards Grid (2x3)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    StatsCard(
                      title: 'Revenue',
                      value: StatsCard.formatCurrency(stats.totalRevenue),
                      changePercentage: 18.0,
                      icon: Icons.attach_money,
                      color: const Color(0xFF1A1A2E),
                    ),
                    StatsCard(
                      title: 'Orders',
                      value: StatsCard.formatNumber(stats.totalOrders),
                      changePercentage: 12.0,
                      icon: Icons.shopping_bag_outlined,
                      color: const Color(0xFF16213E),
                    ),
                    StatsCard(
                      title: 'Users',
                      value: StatsCard.formatNumber(stats.totalUsers),
                      changePercentage: 8.0,
                      icon: Icons.people_outline,
                      color: const Color(0xFF1A1A2E),
                    ),
                    StatsCard(
                      title: 'Sellers',
                      value: StatsCard.formatNumber(stats.totalSellers),
                      changePercentage: 5.0,
                      icon: Icons.store_outlined,
                      color: const Color(0xFF16213E),
                    ),
                    StatsCard(
                      title: 'Products',
                      value: StatsCard.formatNumber(stats.totalProducts),
                      changePercentage: 15.0,
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF1A1A2E),
                    ),
                    StatsCard(
                      title: 'Earnings',
                      value: StatsCard.formatCurrency(stats.totalEarnings),
                      changePercentage: 18.0,
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFFE94560),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Alerts Section
                if (stats.pendingSellers > 0 ||
                    stats.pendingProducts > 0 ||
                    stats.activeDisputes > 0 ||
                    stats.reportedProducts > 0) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE94560),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Requires Attention',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (stats.pendingSellers > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionAlertCard(
                        priority: AlertPriority.high,
                        message: 'sellers pending KYC',
                        count: stats.pendingSellers,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SellerKYCScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  if (stats.pendingProducts > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionAlertCard(
                        priority: AlertPriority.high,
                        message: 'products pending approval',
                        count: stats.pendingProducts,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageProductsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  if (stats.activeDisputes > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionAlertCard(
                        priority: AlertPriority.medium,
                        message: 'disputes need resolution',
                        count: stats.activeDisputes,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.disputeCenter);
                        },
                      ),
                    ),
                  if (stats.reportedProducts > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionAlertCard(
                        priority: AlertPriority.medium,
                        message: 'reported products',
                        count: stats.reportedProducts,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageProductsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                // Revenue Trend Chart
                if (stats.revenueTrend.isNotEmpty)
                  AdminRevenueChart(revenueTrend: stats.revenueTrend),

                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _QuickActionCard(
                      icon: Icons.people_outline,
                      label: 'Users',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.store_outlined,
                      label: 'Sellers',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageSellersScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Products',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageProductsScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Orders',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.manageOrders);
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.gavel_outlined,
                      label: 'Disputes',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.disputeCenter);
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.analytics_outlined,
                      label: 'Analytics',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.analytics);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF1A1A2E),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
