import 'package:flutter/material.dart';

enum AlertPriority { high, medium, low }

class ActionAlertCard extends StatelessWidget {
  final AlertPriority priority;
  final String message;
  final int count;
  final VoidCallback onTap;

  const ActionAlertCard({
    super.key,
    required this.priority,
    required this.message,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final priorityIcon = _getPriorityIcon();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                priorityIcon,
                color: priorityColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count $message',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Requires attention',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case AlertPriority.high:
        return const Color(0xFFDC3545); // Red
      case AlertPriority.medium:
        return const Color(0xFFFFC107); // Yellow/Orange
      case AlertPriority.low:
        return const Color(0xFF17A2B8); // Blue
    }
  }

  IconData _getPriorityIcon() {
    switch (priority) {
      case AlertPriority.high:
        return Icons.error_outline;
      case AlertPriority.medium:
        return Icons.warning_amber_outlined;
      case AlertPriority.low:
        return Icons.info_outline;
    }
  }
}
