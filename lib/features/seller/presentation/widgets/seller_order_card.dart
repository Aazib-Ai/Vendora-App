import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/order.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

class SellerOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onShip;
  final bool isProcessing;

  const SellerOrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.onShip,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: AppTypography.headingSmall,
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                  style: AppTypography.caption,
                ),
                const Divider(height: AppSpacing.lg),
                
                // Customer Info (Simplified for now, in a real app we'd fetch profile)
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    // Placeholder as we don't have user name in Order model directly yet
                    // In a real app we might need to join with profiles or store snapshot
                    const Text('Customer', style: AppTypography.bodyMedium),
                  ],
                ),
              ],
            ),
          ),

          // Order Items
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        // Placeholder image
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.quantity} x ${NumberFormat.currency(symbol: 'Rs ').format(item.unitPrice)}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: 'Rs ').format(item.totalPrice),
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Total & Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: AppTypography.bodyMedium),
                    Text(
                      NumberFormat.currency(symbol: 'Rs ').format(order.total),
                      style: AppTypography.headingSmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.pending || order.status == OrderStatus.processing)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      children: [
                        if (order.status == OrderStatus.pending) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing ? null : onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isProcessing ? null : onAccept,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: isProcessing 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                  )
                                : const Text('Accept'),
                            ),
                          ),
                        ],
                        if (order.status == OrderStatus.processing)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isProcessing ? null : onShip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Mark as Shipped'),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = AppColors.warning;
        label = 'Pending';
        break;
      case OrderStatus.processing:
        color = AppColors.info;
        label = 'Processing';
        break;
      case OrderStatus.shipped:
        color = AppColors.primary;
        label = 'Shipped';
        break;
      case OrderStatus.delivered:
        color = AppColors.success;
        label = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        label = 'Cancelled';
        break;
      case OrderStatus.returned: // Handling potential extra status
        color = Colors.purple;
        label = 'Returned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
