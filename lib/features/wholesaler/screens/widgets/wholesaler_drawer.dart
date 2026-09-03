import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../core/theme/theme.dart';

class WholesalerDrawer extends StatelessWidget {
  const WholesalerDrawer({super.key});

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
    final String email =
        user['email'] ?? 'wholesaler@productsphere.com';

    final String initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'W';

    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive drawer width
    final double drawerWidth = screenWidth < 360
        ? screenWidth * 0.88
        : screenWidth < 600
            ? screenWidth * 0.82
            : screenWidth < 1000
                ? 320
                : 350;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // HEADER
            // =========================
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 400 ? 16 : 20,
                vertical: screenWidth < 400 ? 20 : 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryDark,
                    AppTheme.primary,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth < 400 ? 21 : 24,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth < 400 ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 400 ? 15 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 3),

                        Text(
                          email,
                          style: TextStyle(
                            color:
                                Colors.white.withValues(alpha: 0.75),
                            fontSize: screenWidth < 400 ? 11 : 12,
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

            // =========================
            // MENU ITEMS
            // =========================

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
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
                      Get.toNamed('/wholesaler-product-form');
                    },
                  ),

                  _drawerItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'My Inventory',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/wholesaler-inventory');
                    },
                  ),

                  _drawerItem(
                    icon: Icons.gavel_rounded,
                    label: 'Price Negotiations',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/wholesaler-negotiations');
                    },
                  ),

                  _drawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Received Orders',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/orders-history');
                    },
                  ),

                  _drawerItem(
                    icon: Icons.business_outlined,
                    label: 'Business Settings',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/business-settings');
                    },
                  ),

                  _drawerItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/notifications');
                    },
                  ),
                ],
              ),
            ),

            // =========================
            // LOGOUT
            // =========================

            Divider(
              color: AppTheme.border,
              height: 1,
            ),

            Padding(
              padding: EdgeInsets.all(
                screenWidth < 400 ? 10 : 16,
              ),
              child: ListTile(
                onTap: _logout,

                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 400 ? 8 : 12,
                ),

                leading: Icon(
                  Icons.logout_rounded,
                  color: AppTheme.expired,
                  size: screenWidth < 400 ? 20 : 22,
                ),

                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppTheme.expired,
                    fontSize: screenWidth < 400 ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // DRAWER ITEM
  // =========================

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 2,
      ),
      child: ListTile(
        onTap: onTap,

        minLeadingWidth: 20,

        leading: Icon(
          icon,
          color: AppTheme.textSecondary,
          size: 22,
        ),

        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppTheme.radiusMd),
        ),

        // Better touch area
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
      ),
    );
  }
}