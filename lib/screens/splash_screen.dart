import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/services/settings_service.dart';
import '../routes/app_routes.dart';
import '../core/utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for splash logo display
    await Future.delayed(const Duration(milliseconds: 1800));

    final box = GetStorage();
    final result = await SettingsService.fetchPublicSettings();

    bool isMaintenance = false;
    if (result['success'] == true) {
      final data = result['data'];
      box.write('public_settings', data);
      isMaintenance = data['maintenance_mode'] == 'true';
    }

    final token = box.read('token');
    final role = box.read('role');

    if (isMaintenance && role != 'admin') {
      Get.offAllNamed('/maintenance');
      return;
    }

    if (token != null) {
      if (role == 'admin') {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
    if (token != null) {
      if (role == 'admin') {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Content: Logo & Brand Name
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_mall_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // App Name
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "Product",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: "Sphere",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  const Text(
                    "B2B Local Market Platform",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}