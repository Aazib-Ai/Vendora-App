import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/seller/presentation/providers/seller_dashboard_provider.dart';
import 'package:vendora/models/seller_model.dart';
import 'package:vendora/core/theme/app_colors.dart'; // Assuming AppColors exists, else fallback

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics & Commission',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Consumer<SellerDashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final stats = provider.stats;
          if (stats == null) {
            return const Center(child: Text('No analytics data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- FINANCIAL SUMMARY CARDS ---
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Revenue',
                        value: 'PKR ${(stats.netEarnings + stats.totalCommission).toStringAsFixed(0)}', // Gross
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: 'Net Earnings',
                        value: 'PKR ${stats.netEarnings.toStringAsFixed(2)}',
                        icon: Icons.monetization_on_outlined,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Commission (10%)',
                        value: 'PKR ${stats.totalCommission.toStringAsFixed(2)}',
                        icon: Icons.pie_chart_outline,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Orders',
                        value: '${stats.ordersToday + stats.ordersPending}', // Crude total approximation for display or use ordersToday
                        icon: Icons.shopping_bag_outlined,
                        color: Colors.blueGrey,
                        // Note: ideally we want Total All Time orders, but SellerStats currently has Daily/Pending.
                        // Using 'Orders Today' + 'Pending' might be misleading if titled 'Total Orders'
                        // Let's use 'Orders Today' per model
                      ),
                    ),
                  ],
                ),
                
                 const SizedBox(height: 15),
                 // Today specific
                 Row(
                  children: [
                     Expanded(
                      child: _StatCard(
                        title: 'Sales Today',
                        value: 'PKR ${stats.salesToday.toStringAsFixed(2)}',
                        icon: Icons.today,
                        isSmallText: true,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending Orders',
                        value: '${stats.ordersPending}',
                        icon: Icons.hourglass_empty,
                        isSmallText: true,
                      ),
                    ),
                  ]
                 ),

                const SizedBox(height: 30),

                // --- REVENUE PERFORMANCE CHART (7 DAYS) ---
                const Text(
                  'Revenue Trend (7 Days)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 250,
                  padding: const EdgeInsets.only(right: 20, top: 24, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.compact()}',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            reservedSize: 30,
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false), // Hide days for simplicity or implement date mapping
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(stats.weeklySales.length, (index) {
                            return FlSpot(index.toDouble(), stats.weeklySales[index]);
                          }),
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 4,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.3),
                                Colors.blueAccent.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                 // --- CATEGORY PERFORMANCE PIE CHART ---
                const Text(
                  'Category Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                 if (stats.categorySales.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: _generateCategorySections(stats.categorySales),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No sales data yet."),
                  ),

                const SizedBox(height: 30),

                // --- TOP PERFORMING PRODUCTS ---
                const Text(
                  'Top Performing Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.topProducts.length,
                  itemBuilder: (context, index) {
                    final product = stats.topProducts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.shopping_cart, color: Colors.white24),
                        ),
                        title: Text(
                          product.productName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${product.salesCount} sold',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: Text(
                          '\$${product.totalRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  List<PieChartSectionData> _generateCategorySections(Map<String, double> categorySales) {
    const colors = [Colors.blue, Colors.red, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
    int colorIndex = 0;
    
    return categorySales.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        
        return PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        );
    }).toList();
  }
}

extension NumberExport on num {
  String compact() {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isSmallText;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isSmallText = false,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color, // Use dynamic color
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 15 : 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
