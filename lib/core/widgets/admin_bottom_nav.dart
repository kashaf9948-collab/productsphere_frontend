import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminBottomNav extends StatelessWidget {
  final int activeIndex; // 0=Home, 1=Verifications, 2=Users, 3=Profile

  const AdminBottomNav({Key? key, required this.activeIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.purple.shade700;
    const inactiveColor = Color(0xFF546E7A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ]
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => Get.offAllNamed('/admin-dashboard'),
              ),
              _item(
                icon: Icons.verified_user_outlined,
                activeIcon: Icons.verified_user_rounded,
                label: 'Verifications',
                index: 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () {},
              ),
              _item(
                icon: Icons.people_outline,
                activeIcon: Icons.people_rounded,
                label: 'Users',
                index: 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () {},
              ),
              _item(
                icon: Icons.admin_panel_settings_outlined,
                activeIcon: Icons.admin_panel_settings_rounded,
                label: 'Profile',
                index: 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final isActive = index == activeIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
