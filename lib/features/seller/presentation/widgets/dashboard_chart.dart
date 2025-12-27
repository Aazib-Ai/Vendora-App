import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/seller_stats.dart';

class DashboardChart extends StatelessWidget {
  final List<SalesPoint> salesPoints;

  const DashboardChart({super.key, required this.salesPoints});

  @override
  Widget build(BuildContext context) {
    // If no sales, show empty state or just the chart with 0s
    // salesPoints should be length 7 for a week
    
    // Find max Y for scale
    double maxY = 0;
    for (var p in salesPoints) {
      if (p.amount > maxY) maxY = p.amount;
    }
    maxY = maxY == 0 ? 100 : maxY * 1.2; // Add some headroom

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 5,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xffeaeaea),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < salesPoints.length) {
                       final date = salesPoints[index].date;
                       return Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text(
                             DateFormat('E').format(date)[0], // M, T, W...
                             style: const TextStyle(
                               fontWeight: FontWeight.bold,
                               fontSize: 12,
                               color: Colors.grey
                             ),
                         ),
                       );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY / 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      compactNumber(value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                         color: Colors.grey
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            minX: 0,
            maxX: salesPoints.length.toDouble() - 1,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: salesPoints
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
                    .toList(),
                isCurved: true,
                color: Colors.black, // App Theme
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(
                  show: true,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String compactNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }
}
