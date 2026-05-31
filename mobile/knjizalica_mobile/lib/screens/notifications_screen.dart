import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';
import '../widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.unreadCount > 0)
            TextButton(
              onPressed: notifications.isLoading
                  ? null
                  : () => notifications.markAllRead(),
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifications.load(),
          ),
        ],
      ),
      body: notifications.isLoading
          ? const LoadingWidget(message: 'Loading notifications...')
          : notifications.notifications.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : RefreshIndicator(
                  onRefresh: () => notifications.load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = notifications.notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isRead
                              ? Colors.grey.shade300
                              : Theme.of(context).colorScheme.primary,
                          child: Icon(
                            item.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: item.isRead ? Colors.grey : Colors.white,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                item.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(item.message),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMd().add_jm().format(
                                    item.createdAt.toLocal(),
                                  ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: item.isRead
                            ? null
                            : () => notifications.markRead(item.id),
                      );
                    },
                  ),
                ),
    );
  }
}
