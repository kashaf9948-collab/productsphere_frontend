import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/theme.dart';

class ClientBottomNav extends StatelessWidget {
  final int activeIndex; // 0=Shop, 1=Search, 2=Negotiations, 3=Profile

  const ClientBottomNav({Key? key, required this.activeIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const activeColor = AppTheme.primary; // Teal
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
                icon: Icons.local_mall_outlined,
                activeIcon: Icons.local_mall_rounded,
                label: 'Marketplace',
                index: 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => Get.offAllNamed('/dashboard'),
              ),
              _item(
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                label: 'Search',
                index: 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () {},
              ),
              _item(
                icon: Icons.gavel_rounded,
                activeIcon: Icons.gavel_rounded,
                label: 'Negotiations',
                index: 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () {},
              ),
              _item(
                icon: Icons.account_circle_outlined,
                activeIcon: Icons.account_circle_rounded,
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
