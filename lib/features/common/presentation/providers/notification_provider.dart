import 'package:flutter/foundation.dart';
import 'package:vendora/core/data/repositories/notification_repository.dart';
import 'package:vendora/models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository;
  
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationProvider(this._notificationRepository);

  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
     // Don't notify listeners here to avoid flicker if just refreshing, 
     // or do notify if initial load. 
     if (_notifications.isEmpty) notifyListeners();

    final result = await _notificationRepository.getNotifications(userId);

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      final old = _notifications[index];
      _notifications[index] = old.copyWith(isRead: true);
      notifyListeners();
      
      final result = await _notificationRepository.markAsRead(notificationId);
      result.fold(
        (failure) {
           // Revert on failure
           _notifications[index] = old;
           _error = failure.message; // or silent
           notifyListeners();
        },
        (_) {},
      );
    }
  }

  Future<void> markAllAsRead(String userId) async {
    // Optimistic
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
    }
    notifyListeners();

    final result = await _notificationRepository.markAllAsRead(userId);
    
    result.fold(
        (failure) {
            // Revert complex? Just reload
            loadNotifications(userId);
        },
        (_) {}
    );
  }
}
