import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/admin_bottom_nav.dart';
import '../../core/widgets/snackbars.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _pendingWholesalers = [];
  List<dynamic> _approvedWholesalers = [];
  List<dynamic> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AuthService.fetchPendingWholesalers(),
        ProductService.fetchApprovedWholesalers(),
        ProductService.fetchWholesaleProducts(),
      ]);
      setState(() {
        _pendingWholesalers = results[0];
        _approvedWholesalers = results[1];
        _allProducts = results[2];
        _isLoading = false;
      });
    } catch (e) {
      print('Admin Dashboard fetch data error: $e');
      setState(() => _isLoading = false);
    }
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
      if (status == 'approved') {
        AppSnackbars.success(
          title: "Action Successful",
          message: "Business '$name' is now approved.",
        );
      } else {
        AppSnackbars.error(
          title: "Action Successful",
          message: "Business '$name' is now rejected.",
        );
      }
      _fetchData(); // reload list
    } else {
      AppSnackbars.error(
        title: "Action Failed",
        message: result['message'] ?? "Failed to update business status",
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
      backgroundColor: AppTheme.background,
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: 0),
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
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
                    colors: [AppTheme.secondaryDark, AppTheme.secondary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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
                      value: _approvedWholesalers.length.toString(),
                      color: AppTheme.secondaryLight,
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
                      value: _allProducts.where((p) => p['status'] != 'flagged').length.toString(),
                      color: Colors.blue,
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      label: 'Flagged Listings',
                      value: _allProducts.where((p) => p['status'] == 'flagged').length.toString(),
                      color: Colors.red,
                      icon: Icons.report_problem_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // --- PENDING VERIFICATION SUMMARY ---
              const Text(
                'Pending Business Verifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [AppTheme.cardShadow],
                  border: Border.all(color: AppTheme.border, width: 0.6),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 40, color: AppTheme.secondaryDark),
                    const SizedBox(height: 12),
                    Text(
                      _pendingWholesalers.isEmpty
                          ? 'No pending applications'
                          : '${_pendingWholesalers.length} Wholesaler applications pending review',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.secondaryDark),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed('/admin-verifications'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.secondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: const Text('Go to Verifications', style: TextStyle(color: AppTheme.secondary)),
                      ),
                    ),
                  ],
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

}