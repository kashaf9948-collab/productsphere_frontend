import 'package:flutter/material.dart';
import '../services/buyer_service.dart';
import '../../../core/theme/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final data = await BuyerService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    final success = await BuyerService.markNotificationAsRead(id);
    if (success) {
      _loadNotifications();
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'bid':
        return Icons.gavel_outlined;
      case 'verification':
        return Icons.verified_user_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order':
        return AppTheme.primaryDark;
      case 'bid':
        return AppTheme.secondaryDark;
      case 'verification':
        return AppTheme.textDark;
      default:
        return AppTheme.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryDark))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 70, color: AppTheme.textHint),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Updates about your orders, bids, and profile will appear here.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primaryDark,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final isRead = item['is_read'] == 1 || item['is_read'] == true;
                      final type = item['type'] ?? 'system';

                      return Card(
                        elevation: isRead ? 1 : 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isRead ? Colors.grey.shade200 : AppTheme.primaryDark.withValues(alpha: 0.3),
                            width: isRead ? 1 : 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: _getTypeColor(type).withValues(alpha: 0.15),
                            child: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.expired,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['message'] ?? '',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['created_at'] != null
                                      ? item['created_at'].toString().split('T')[0]
                                      : 'Recently',
                                  style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            if (!isRead && item['id'] != null) {
                              _markRead(int.parse(item['id'].toString()));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
