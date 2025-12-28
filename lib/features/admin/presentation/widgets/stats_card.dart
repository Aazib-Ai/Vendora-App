import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final double? changePercentage;
  final IconData icon;
  final Color? color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.changePercentage,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercentage != null && changePercentage! >= 0;
    final cardColor = color ?? const Color(0xFF1A1A2E);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.7),
                size: 32,
              ),
              if (changePercentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${changePercentage!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Format currency values
  static String formatCurrency(double value) {
    if (value >= 1000000) {
      return 'PKR ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'PKR ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'PKR ${NumberFormat('#,###').format(value)}';
  }

  /// Format number values
  static String formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,###').format(value);
  }
}
