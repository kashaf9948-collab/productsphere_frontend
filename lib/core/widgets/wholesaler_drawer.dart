import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/theme.dart';

class WholesalerDrawer extends StatelessWidget {
  const WholesalerDrawer({Key? key}) : super(key: key);

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
    final String name = user['name'] ?? 'Wholesaler';
    final String email = user['email'] ?? 'wholesaler@productsphere.com';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'W';

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
              color: Colors.indigo.shade700,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.25),
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
                            color: Colors.white.withOpacity(0.75),
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
              icon: Icons.storefront_outlined,
              label: 'Shop Dashboard',
              onTap: () {
                Get.back();
                Get.offAllNamed('/dashboard');
              },
            ),
            _drawerItem(
              icon: Icons.add_circle_outline_rounded,
              label: 'Publish Product',
              onTap: () {
                Get.back();
              },
            ),
            _drawerItem(
              icon: Icons.inventory_2_outlined,
              label: 'My Inventory',
              onTap: () {
                Get.back();
              },
            ),
            _drawerItem(
              icon: Icons.gavel_rounded,
              label: 'Price Negotiations',
              onTap: () {
                Get.back();
              },
            ),
            _drawerItem(
              icon: Icons.receipt_long_outlined,
              label: 'Received Orders',
              onTap: () {
                Get.back();
              },
            ),
            _drawerItem(
              icon: Icons.business_outlined,
              label: 'Business Settings',
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
