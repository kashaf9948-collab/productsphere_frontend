import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/client_bottom_nav.dart';
import '../../core/widgets/wholesaler_bottom_nav.dart';
import '../../core/widgets/admin_bottom_nav.dart';
import '../../core/widgets/snackbars.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final box = GetStorage();
  late Map<String, dynamic> _user;
  late String _role;

  @override
  void initState() {
    super.initState();
    final userData = box.read('user');
    _role = box.read('role') ?? 'buyer';
    _user = userData is Map ? Map<String, dynamic>.from(userData) : {};
  }

  void _logout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, elevation: 0),
            onPressed: () {
              box.erase();
              Get.offAllNamed('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _user['name'] ?? 'User';
    final email = _user['email'] ?? '';
    final phone = _user['phone'] ?? '';
    final gender = _user['gender'] ?? '';
    final status = _user['status'] ?? 'approved';
    final licenseNo = _user['license_no'] ?? '';
    final businessAddress = _user['business_address'] ?? '';

    final isWholesaler = _role == 'wholesaler';
    final isAdmin = _role == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: isAdmin
          ? const AdminBottomNav(activeIndex: 3)
          : isWholesaler
              ? const WholesalerBottomNav(activeIndex: 3)
              : const ClientBottomNav(activeIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color.fromARGB(255, 4, 185, 161)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const BackButton(color: Colors.white),
                        const Spacer(),
                        const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          onPressed: _logout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                    if (isWholesaler) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'approved' ? Colors.green.withOpacity(0.85) : Colors.orange.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status == 'approved' ? Icons.verified_rounded : Icons.access_time_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              status == 'approved' ? 'Verified' : 'Pending Approval',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _sectionCard(
                      title: 'Account Information',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _infoRow(Icons.email_outlined, 'Email', email),
                        _infoRow(Icons.phone_outlined, 'Phone', phone.isNotEmpty ? phone : '—'),
                        _infoRow(Icons.wc_rounded, 'Gender', gender.isNotEmpty ? _capitalize(gender) : '—'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (isWholesaler) ...[
                      _sectionCard(
                        title: 'Business Information',
                        icon: Icons.business_outlined,
                        children: [
                          _infoRow(Icons.badge_outlined, 'License / NTN', licenseNo.isNotEmpty ? licenseNo : '—'),
                          _infoRow(Icons.location_on_outlined, 'Business Address', businessAddress.isNotEmpty ? businessAddress : '—'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Business Settings Button
                      _actionTile(
                        icon: Icons.settings_outlined,
                        label: 'Business Settings',
                        subtitle: 'Manage your shop profile & documents',
                        onTap: () => Get.toNamed('/business-settings'),
                      ),
                      const SizedBox(height: 12),

                      // Orders link
                      _actionTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'Incoming Orders',
                        subtitle: 'View all purchase orders',
                        onTap: () => Get.toNamed('/orders-history'),
                      ),
                    ],

                    if (!isWholesaler && !isAdmin) ...[
                      _actionTile(
                        icon: Icons.shopping_bag_outlined,
                        label: 'My Orders',
                        subtitle: 'View your placed orders',
                        onTap: () => Get.toNamed('/orders-history'),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Logout
                    _actionTile(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      subtitle: 'Sign out of your account',
                      onTap: _logout,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String label, required String subtitle, required VoidCallback onTap, Color? color}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: (color ?? AppTheme.primary).withOpacity(0.1),
          child: Icon(icon, size: 20, color: color ?? AppTheme.primary),
        ),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded, color: color ?? AppTheme.textSecondary),
      ),
    );
  }

  String _capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
}