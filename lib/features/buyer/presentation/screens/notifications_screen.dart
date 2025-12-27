import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vendora/features/auth/presentation/providers/auth_provider.dart';
import 'package:vendora/features/common/presentation/providers/notification_provider.dart';
import 'package:vendora/models/notification.dart' as model; // Alias to avoid clash

class BuyerNotificationsScreen extends StatefulWidget {
  const BuyerNotificationsScreen({super.key});

  @override
  State<BuyerNotificationsScreen> createState() => _BuyerNotificationsScreenState();
}

class _BuyerNotificationsScreenState extends State<BuyerNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<NotificationProvider>().loadNotifications(user.id);
      }
    });
  }

  IconData _getIconForType(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.orderStatusUpdate:
        return Icons.local_shipping;
      case model.NotificationType.productApproval: // Seller oriented but maybe buyer gets it if they sell?
        return Icons.check_circle;
      case model.NotificationType.sellerApproval:
        return Icons.store;
      case model.NotificationType.disputeUpdate:
        return Icons.gavel;
      case model.NotificationType.priceDropAlert:
        return Icons.price_change;
      case model.NotificationType.lowStockAlert:
        return Icons.inventory;
      case model.NotificationType.newReview:
        return Icons.star;
      case model.NotificationType.other:
      default:
        return Icons.notifications;
    }
  }
  
  Color _getColorForType(model.NotificationType type) {
     switch (type) {
      case model.NotificationType.orderStatusUpdate:
        return Colors.blue;
      case model.NotificationType.disputeUpdate:
        return Colors.red;
       case model.NotificationType.priceDropAlert:
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  void _handleTap(model.Notification notification) async {
    if (!notification.isRead) {
       context.read<NotificationProvider>().markAsRead(notification.id);
    }
    
    // Navigate based on type
    // For now, mostly just showing details or generic navigation
    // Real implementation would parse data['targetId'] etc.
    if (notification.type == model.NotificationType.orderStatusUpdate) {
        // Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: notification.data['orderId']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
         backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
            IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: () {
                    final user = context.read<AuthProvider>().currentUser;
                    if (user != null) {
                        context.read<NotificationProvider>().markAllAsRead(user.id);
                    }
                },
                tooltip: "Mark all as read",
            )
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.notifications.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          return ListView.separated(
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return Container(
                color: notification.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForType(notification.type).withOpacity(0.1),
                    child: Icon(_getIconForType(notification.type), color: _getColorForType(notification.type)),
                  ),
                  title: Text(
                      notification.title, 
                      style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)
                  ),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const SizedBox(height: 4),
                          Text(notification.body),
                          const SizedBox(height: 4),
                          Text(timeago.format(notification.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                      ],
                  ),
                  onTap: () => _handleTap(notification),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
