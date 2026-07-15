import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/utils/theme.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final settings = box.read('public_settings') ?? {};
    final String platformName = settings['platform_name'] ?? 'Product Sphere';
    final String supportEmail = settings['contact_email'] ?? 'support@productsphere.com';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Maintenance Icon
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFFFF3E0),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 50,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                '$platformName is Under Maintenance',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'We are performing scheduled updates to improve your experience. We will be back online shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Support contact info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Contact Support: $supportEmail',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Option for Admin to log in anyway
              TextButton.icon(
                onPressed: () => Get.offAllNamed('/login'),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: const Text('Admin Login'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}