import 'package:flutter/foundation.dart';

import '../models/notification_models.dart';
import '../services/api_service.dart';
import '../services/notification_hub_service.dart';
import '../utils/api_error_parser.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({
    required ApiService api,
    required NotificationHubService hubService,
  })  : _api = api,
        _hubService = hubService {
    _hubService.onNotificationReceived = _onPushReceived;
  }

  final ApiService _api;
  final NotificationHubService _hubService;

  List<NotificationDto> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final page = await _api.getNotifications(pageSize: 50);
      notifications = page.items;
      final count = await _api.getUnreadCount();
      unreadCount = count.count;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _api.getUnreadCount();
      unreadCount = count.count;
      notifyListeners();
    } catch (_) {
      // Ignore count refresh errors.
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.markNotificationRead(id);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index >= 0) {
        final existing = notifications[index];
        notifications[index] = NotificationDto(
          id: existing.id,
          title: existing.title,
          message: existing.message,
          isRead: true,
          createdAt: existing.createdAt,
        );
        unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      notifications = notifications
          .map(
            (n) => NotificationDto(
              id: n.id,
              title: n.title,
              message: n.message,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      unreadCount = 0;
      notifyListeners();
    } catch (e) {
      errorMessage = e is ApiException ? e.message : e.toString();
      notifyListeners();
    }
  }

  void _onPushReceived(NotificationDto notification) {
    notifications = [notification, ...notifications];
    if (!notification.isRead) {
      unreadCount += 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _hubService.onNotificationReceived = null;
    super.dispose();
  }
}
