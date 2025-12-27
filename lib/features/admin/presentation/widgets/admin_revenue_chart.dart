import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminRevenueChart extends StatelessWidget {
  final List<double> revenueTrend;

  const AdminRevenueChart({super.key, required this.revenueTrend});

  @override
  Widget build(BuildContext context) {
    // Calculate max value for Y-axis scaling
    double maxY = revenueTrend.isEmpty ? 100 : revenueTrend.reduce((a, b) => a > b ? a : b);
    maxY = maxY == 0 ? 100 : maxY * 1.2; // Add 20% headroom

    // If we have 30 days, show every 5th day label
    final showInterval = revenueTrend.length > 15 ? 5.0 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend (Last 30 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: Padding(
              padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFEAEAEA),
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
                        interval: showInterval,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < revenueTrend.length) {
                            // Show day number (e.g., 1, 5, 10, 15, 20, 25, 30)
                            final dayNumber = index + 1;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dayNumber.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  color: Colors.grey,
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
                            _compactNumber(value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.left,
                          );
                        },
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (revenueTrend.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: revenueTrend
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF1A1A2E),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: revenueTrend.length <= 7, // Only show dots for weekly view
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A1A2E).withOpacity(0.3),
                            const Color(0xFF1A1A2E).withOpacity(0.05),
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
          ),
        ],
      ),
    );
  }

  String _compactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }
}
