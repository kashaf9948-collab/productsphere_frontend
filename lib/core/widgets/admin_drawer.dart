import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/theme.dart';

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

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: Colors.purple.shade700,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                            fontSize: 12,
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
            const SizedBox(height: 12),

            // Items
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
                Get.offAllNamed('/admin-dashboard');
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
              icon: Icons.shopping_bag_outlined,
              label: 'Registered Buyers',
              onTap: () {
                Get.back();
              },
            ),
            _drawerItem(
              icon: Icons.category_outlined,
              label: 'Category Management',
              onTap: () {
                Get.back();
              },
            ),
            _drawerItem(
              icon: Icons.settings_outlined,
              label: 'System Settings',
              onTap: () {
                Get.back();
              },
            ),

            const Spacer(),
            const Divider(color: AppTheme.border),

            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                onTap: _logout,
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.expired,
                  size: 22,
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppTheme.expired,
                    fontSize: 15,
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
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
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
