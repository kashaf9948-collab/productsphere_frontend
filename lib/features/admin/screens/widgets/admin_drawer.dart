import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../core/theme/theme.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  void _logout() {
    final box = GetStorage();
    box.remove('token');
    box.remove('user');
    box.remove('role');
    box.remove('isLoggedIn');
    box.remove('userName');
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final user = box.read('user') ?? {};
    final String name = user['name'] ?? 'Admin User';
    final String email = user['email'] ?? 'admin@productsphere.com';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    // Screen ki height aur width get karne ke liye (Responsiveness ke liye)
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Drawer ki width ko responsive banane ke liye (Tablet par thoda bada, mobile par standard)
    final drawerWidth = screenWidth > 600 ? 320.0 : screenWidth * 0.75;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Responsive Padding & Text scaling)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? 24 : 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondaryDark, AppTheme.secondary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: screenWidth > 600 ? 28 : 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth > 600 ? 22 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth > 600 ? 17 : 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: screenWidth > 600 ? 13 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Scrollable Items List (Overflow se bachne ke liye)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _drawerItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Overview Dashboard',
                        onTap: () {
                          Get.back();
                          Get.offAllNamed('/admin-dashboard');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.verified_user_outlined,
                        label: 'Business Verifications',
                        onTap: () {
                          Get.back();
                          Get.offAllNamed('/admin-verifications');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.storefront_outlined,
                        label: 'Wholesalers Catalog',
                        onTap: () {
                          Get.back();
                          Get.offAllNamed('/admin-catalog');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Registered Buyers',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/admin-buyers');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Marketplace Orders',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/admin-orders');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.category_outlined,
                        label: 'Category Management',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/admin-categories');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.gavel_rounded,
                        label: 'Price Negotiations',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/admin-negotiations');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.settings_outlined,
                        label: 'System Settings',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/admin-settings');
                        },
                      ),
                      _drawerItem(
                        icon: Icons.notifications_active_outlined,
                        label: 'Notifications Audit',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/admin-notifications');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Divider(color: AppTheme.border),

              // Logout Button (Fixed at bottom)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  onTap: _logout,
                  leading: Icon(
                    Icons.logout_rounded,
                    color: AppTheme.expired,
                    size: 22,
                  ),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppTheme.expired,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true, // Choti screens ke liye compact spacing
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.textSecondary, size: 21),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}