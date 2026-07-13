import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/theme.dart';

class AppSnackbars {
  static void success({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFE8F5E9), // Clean light green
      colorText: const Color(0xFF2E7D32), // Dark green
      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: AppTheme.radiusSm,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  static void error({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFFFEBEE), // Clean light red
      colorText: const Color(0xFFC62828), // Dark red
      icon: const Icon(Icons.error_rounded, color: Color(0xFFC62828)),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: AppTheme.radiusSm,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  static void warning({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFFFF3E0), // Clean light orange
      colorText: const Color(0xFFEF6C00), // Dark orange
      icon: const Icon(Icons.warning_rounded, color: Color(0xFFEF6C00)),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: AppTheme.radiusSm,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  static void info({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFE3F2FD), // Clean light blue
      colorText: const Color(0xFF1565C0), // Dark blue
      icon: const Icon(Icons.info_rounded, color: Color(0xFF1565C0)),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: AppTheme.radiusSm,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
}