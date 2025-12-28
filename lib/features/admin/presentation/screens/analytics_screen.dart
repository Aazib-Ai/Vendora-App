import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendora/features/admin/domain/repositories/admin_repository.dart';
import 'package:vendora/features/admin/presentation/providers/admin_analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AdminAnalyticsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = AdminAnalyticsProvider(context.read<IAdminRepository>());
    _provider.fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Platform Analytics'),
          elevation: 0,
        ),
        body: Consumer<AdminAnalyticsProvider>(
          builder: (context, provider, child) {
            if (provider.state == AnalyticsState.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.state == AnalyticsState.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'An error occurred',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: provider.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final analyticsData = provider.analyticsData;
            final commissionData = provider.commissionData;

            if (analyticsData == null) {
              return const Center(child: Text('No data available'));
            }

            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Selector
                    _buildDateRangeSelector(provider),
                    const SizedBox(height: 24),

                    // Revenue Overview Cards
                    _buildRevenueOverview(analyticsData),
                    const SizedBox(height: 24),

                    // GMV Trend Chart
                    _buildSectionTitle('GMV Trend'),
                    const SizedBox(height: 12),
                    _buildGMVChart(analyticsData.gmvTrend),
                    const SizedBox(height: 24),

                    // User Growth Chart
                    _buildSectionTitle('User Growth'),
                    const SizedBox(height: 12),
                    _buildUserGrowthChart(analyticsData.userGrowth),
                    const SizedBox(height: 24),

                    // Top Categories
                    _buildSectionTitle('Top Categories'),
                    const SizedBox(height: 12),
                    _buildTopCategories(analyticsData.topCategories),
                    const SizedBox(height: 24),

                    // Top Sellers
                    _buildSectionTitle('Top Sellers'),
                    const SizedBox(height: 12),
                    _buildTopSellers(analyticsData.topSellers),
                    const SizedBox(height: 24),

                    // Commission Tracking
                    if (commissionData != null) ...[
                      _buildSectionTitle('Commission Tracking'),
                      const SizedBox(height: 12),
                      _buildCommissionTracking(commissionData),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(AdminAnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text(
              'Date Range:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<AnalyticsDateRange>(
                value: provider.selectedRange,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: AnalyticsDateRange.last7Days,
                    child: Text('Last 7 Days'),
                  ),
                  DropdownMenuItem(
                    value: AnalyticsDateRange.last30Days,
                    child: Text('Last 30 Days'),
                  ),
                  DropdownMenuItem(
                    value: AnalyticsDateRange.last90Days,
                    child: Text('Last 90 Days'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider.setDateRange(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueOverview(dynamic analyticsData) {
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total GMV',
                currencyFormatter.format(analyticsData.totalGMV),
                Icons.attach_money,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Platform Revenue',
                currencyFormatter.format(analyticsData.platformRevenue),
                Icons.account_balance,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Avg Order Value',
                currencyFormatter.format(analyticsData.averageOrderValue),
                Icons.shopping_cart,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Conversion Rate',
                '${analyticsData.conversionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGMVChart(List<dynamic> gmvTrend) {
    if (gmvTrend.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No GMV data available')),
        ),
      );
    }

    final spots = gmvTrend.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= gmvTrend.length) return const Text('');
                      final date = gmvTrend[value.toInt()].date;
                      return Text(
                        DateFormat('MMM d').format(date),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart(List<dynamic> userGrowth) {
    if (userGrowth.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No user growth data available')),
        ),
      );
    }

    final barGroups = userGrowth.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.newUsers.toDouble(),
            color: Colors.green,
            width: 16,
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= userGrowth.length) return const Text('');
                      final date = userGrowth[value.toInt()].date;
                      return Text(
                        DateFormat('MMM d').format(date),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategories(List<dynamic> categories) {
    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No category data available')),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.primaries[index % Colors.primaries.length],
              child: Text('${index + 1}'),
            ),
            title: Text(category.categoryName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: category.percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    Colors.primaries[index % Colors.primaries.length],
                  ),
                ),
                const SizedBox(height: 4),
                Text('${category.percentage.toStringAsFixed(1)}%'),
              ],
            ),
            trailing: Text(
              currencyFormatter.format(category.revenue),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSellers(List<dynamic> sellers) {
    if (sellers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No seller data available')),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sellers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? Colors.amber : Colors.grey,
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(seller.businessName),
            subtitle: Text('${seller.orderCount} orders'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(seller.totalRevenue),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Commission: ${currencyFormatter.format(seller.commission)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommissionTracking(dynamic commissionData) {
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Column(
      children: [
        // Total Platform Earnings Card
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 48, color: Colors.green[700]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Platform Earnings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(commissionData.totalPlatformEarnings),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From ${commissionData.totalOrders} orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Commission by Seller
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Commission by Seller',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commissionData.commissionBySeller.length.clamp(0, 10),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final seller = commissionData.commissionBySeller[index];
                  return ExpansionTile(
                    title: Text(seller.businessName),
                    subtitle: Text('${seller.orderCount} orders'),
                    trailing: Text(
                      currencyFormatter.format(seller.commissionAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCommissionDetail(
                              'Gross Sales',
                              currencyFormatter.format(seller.grossSales),
                            ),
                            _buildCommissionDetail(
                              'Commission (10%)',
                              currencyFormatter.format(seller.commissionAmount),
                            ),
                            _buildCommissionDetail(
                              'Net Earnings',
                              currencyFormatter.format(seller.netEarnings),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
