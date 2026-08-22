import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import './app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final box = GetStorage();
    final token = box.read('token');
    final role = box.read('role');

    if (token == null) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (route == AppRoutes.dashboard && role == 'admin') {
      return const RouteSettings(name: AppRoutes.adminDashboard);
    }
    
    if (route == AppRoutes.adminDashboard && role != 'admin') {
      return const RouteSettings(name: AppRoutes.dashboard);
    }

    return null;
  }
}