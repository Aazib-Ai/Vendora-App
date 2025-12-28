import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the chart library

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sales',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Sales Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Total Sales',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PKR 500,000',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat('This Month', 'PKR 50,000'),
                        _miniStat('Orders', '45'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // REAL SALES CHART
            const Text(
              'Revenue Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12, right: 20, left: 10),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    _mainData(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Recent Sales
            const Text(
              'Recent Sales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.shopping_bag, color: Colors.black87, size: 20),
                    ),
                    title: const Text('Product Sale', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Order #${index + 1024}'),
                    trailing: const Text(
                      'PKR 5,000',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Chart Logic & Styling ---
  LineChartData _mainData() {
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (value.toInt() >= 0 && value.toInt() < days.length) {
                return Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}k', style: const TextStyle(fontSize: 10, color: Colors.grey));
            },
            reservedSize: 35,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 2),
            FlSpot(1, 1.5),
            FlSpot(2, 4),
            FlSpot(3, 3.2),
            FlSpot(4, 5),
            FlSpot(5, 3.8),
            FlSpot(6, 4.5),
          ],
          isCurved: true,
          gradient: const LinearGradient(colors: [Colors.black, Colors.blueAccent]),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.1), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
