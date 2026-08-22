import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../core/theme/theme.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _allNotifications = [];
  List<dynamic> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_filterNotifications);
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    final data = await AdminService.fetchAdminNotificationsAudit();
    if (mounted) {
      setState(() {
        _allNotifications = data;
        _isLoading = false;
      });
      _filterNotifications();
    }
  }

  void _filterNotifications() {
    final index = _tabController.index;
    setState(() {
      if (index == 0) {
        _filteredNotifications = _allNotifications;
      } else if (index == 1) {
        // Buyer Activity
        _filteredNotifications = _allNotifications
            .where((n) => (n['sender_role'] ?? '').toString().toLowerCase() == 'buyer')
            .toList();
      } else if (index == 2) {
        // Wholesaler Activity
        _filteredNotifications = _allNotifications
            .where((n) => (n['sender_role'] ?? '').toString().toLowerCase() == 'wholesaler')
            .toList();
      } else {
        // System & Admin Alerts
        _filteredNotifications = _allNotifications
            .where((n) => (n['sender_role'] ?? '').toString().toLowerCase() == 'admin' ||
                          (n['sender_role'] ?? '').toString().toLowerCase() == 'system')
            .toList();
      }
    });
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toLowerCase()) {
      case 'buyer':
        return Colors.blue.shade700;
      case 'wholesaler':
        return Colors.orange.shade800;
      case 'admin':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications Audit Log', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAuditLogs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Buyers'),
            Tab(text: 'Wholesalers'),
            Tab(text: 'System'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryDark))
          : _filteredNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 70, color: AppTheme.textLight.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No Notification Logs Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Activity notifications sent across the platform will be listed here.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textThird),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAuditLogs,
                  color: AppTheme.primaryDark,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final item = _filteredNotifications[index];
                      final senderRole = item['sender_role'] ?? 'system';
                      final recipientName = item['recipient_name'] ?? 'User #${item['user_id']}';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleBadgeColor(senderRole).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _getRoleBadgeColor(senderRole).withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      senderRole.toUpperCase(),
                                      style: TextStyle(
                                        color: _getRoleBadgeColor(senderRole),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'From: ${item['sender_name'] ?? 'System'} → To: $recipientName',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text(
                                item['title'] ?? 'Notification',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['message'] ?? '',
                                style: const TextStyle(color: AppTheme.textLight, fontSize: 13, height: 1.3),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Type: ${item['type'] ?? 'system'}',
                                    style: TextStyle(color: AppTheme.textThird, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    item['created_at'] != null
                                        ? item['created_at'].toString().replaceFirst('T', ' ').split('.')[0]
                                        : '',
                                    style: TextStyle(color: AppTheme.textThird, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
