import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/admin_bottom_nav.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/admin_bottom_nav.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _pendingWholesalers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await AuthService.fetchPendingWholesalers();
    setState(() {
      _pendingWholesalers = data;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(int userId, String name, String status) async {
    // Show a loading dialog
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final result = await AuthService.updateBusinessStatus(userId, status);
    
    Get.back(); // close dialog

    if (result['success']) {
      Get.snackbar(
        "Action Successful",
        "Business '$name' is now $status.",
        backgroundColor: status == 'approved' ? AppTheme.activeLight : AppTheme.expiredLight,
        colorText: status == 'approved' ? AppTheme.active : AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
      _fetchData(); // reload list
    } else {
      Get.snackbar(
        "Action Failed",
        result['message'] ?? "Failed to update business status",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _logout() {
    AuthService.logout();
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final user = box.read('user') ?? {};
    final String name = user['name'] ?? 'Admin';
    final String email = user['email'] ?? 'admin@productsphere.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: 0),
      appBar: AppBar(
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Control Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ADMIN WELCOME HEADER ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- STATS GRID ---
              const Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: 'Verified Businesses',
                      value: '18',
                      color: Colors.green,
                      icon: Icons.verified_user_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: 'Pending Approvals',
                      value: _pendingWholesalers.length.toString(),
                      color: Colors.orange,
                      icon: Icons.pending_actions_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: 'Active Products',
                      value: '48',
                      color: Colors.blue,
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: 'Flagged Listings',
                      value: '0',
                      color: Colors.red,
                      icon: Icons.report_problem_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // --- PENDING VERIFICATION LIST ---
              const Text(
                'Pending Business Verifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (_pendingWholesalers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'All caught up!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No businesses are currently pending approval.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingWholesalers.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 24),
                    itemBuilder: (context, index) {
                      final business = _pendingWholesalers[index];
                      return _verificationItem(business);
                    },
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationItem(dynamic business) {
    final int userId = business['id'];
    final String businessName = business['name'] ?? 'Unnamed Business';
    final String email = business['email'] ?? 'No email';
    final String phone = business['phone'] ?? 'No phone';
    final String licenseNo = business['license_no'] ?? 'N/A';
    final String address = business['business_address'] ?? 'No address provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                color: Colors.purple.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Email: $email  |  Phone: $phone',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
                  onPressed: () => _updateStatus(userId, businessName, 'approved'),
                  tooltip: 'Approve Business',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
                  onPressed: () => _updateStatus(userId, businessName, 'rejected'),
                  tooltip: 'Reject Business',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'License / NTN: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                  ),
                  Text(
                    licenseNo,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
