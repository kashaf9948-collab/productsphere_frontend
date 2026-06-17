import 'package:get/get.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard/dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/wholesale_catalog_screen.dart';
import 'auth_middleware.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminCatalog = '/admin-catalog';

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: login,
      page: () => LoginScreen(),
    ),
    GetPage(
      name: register,
      page: () => RegisterScreen(),
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: adminDashboard,
      page: () => const AdminDashboardScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: adminCatalog,
      page: () => const WholesaleCatalogScreen(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
