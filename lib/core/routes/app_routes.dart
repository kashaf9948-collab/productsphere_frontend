import 'package:get/get.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/buyer/screens/dashboard.dart';
import '../../features/admin/screens/admin_dashboard.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/wholesale_catalog_screen.dart';
import '../../features/admin/screens/category_management_screen.dart';
import '../../features/wholesaler/screens/inventory_screen.dart';
import '../../features/wholesaler/screens/product_form_screen.dart';
import '../../features/wholesaler/screens/business_settings_screen.dart';
import '../../features/buyer/screens/cart_screen.dart';
import '../../features/buyer/screens/buyer_settings_screen.dart';
import '../../features/buyer/screens/negotiations_list_screen.dart';
import '../../features/buyer/screens/bid_checkout_screen.dart';
import '../../features/wholesaler/screens/wholesaler_negotiations_screen.dart';
import '../../features/admin/screens/admin_negotiations_screen.dart';
import '../../features/admin/screens/buyers_management_screen.dart';
import '../../features/admin/screens/buyer_activity_screen.dart';
import '../../features/admin/screens/orders_audit_screen.dart';
import '../../features/admin/screens/admin_verifications_screen.dart';
import '../../features/buyer/screens/orders_history_screen.dart';
import '../../features/admin/screens/maintenance_screen.dart';
import '../../features/buyer/screens/notifications_screen.dart';
import '../../features/admin/screens/admin_notifications_screen.dart';
import './auth_middleware.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminCatalog = '/admin-catalog';
  static const String adminCategories = '/admin-categories';
  static const String wholesalerInventory = '/wholesaler-inventory';
  static const String wholesalerProductForm = '/wholesaler-product-form';
  static const String cart = '/cart';
  static const String buyerNegotiations = '/buyer-negotiations';
  static const String wholesalerNegotiations = '/wholesaler-negotiations';
  static const String adminNegotiations = '/admin-negotiations';
  static const String bidCheckout = '/bid-checkout';
  static const String adminBuyers = '/admin-buyers';
  static const String buyerActivity = '/buyer-activity';
  static const String adminOrders = '/admin-orders';
  static const String ordersHistory = '/orders-history';
  static const String profile = '/profile';
  static const String businessSettings = '/business-settings';
  static const String adminSettings = '/admin-settings';
  static const String buyerSettings = '/buyer-settings';
  static const String adminVerifications = '/admin-verifications';
  static const String maintenance = '/maintenance';
  static const String notifications = '/notifications';
  static const String adminNotifications = '/admin-notifications';

  static final List<GetPage<dynamic>> pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: register, page: () => RegisterScreen()),
    GetPage(name: dashboard, page: () => const DashboardScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminDashboard, page: () => const AdminDashboardScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminCatalog, page: () => const WholesaleCatalogScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminCategories, page: () => const CategoryManagementScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: wholesalerInventory, page: () => const WholesalerInventoryScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: wholesalerProductForm, page: () => const ProductFormScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: cart, page: () => const CartScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: buyerNegotiations, page: () => const NegotiationsListScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: wholesalerNegotiations, page: () => const WholesalerNegotiationsScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminNegotiations, page: () => const AdminNegotiationsScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: bidCheckout, page: () => const BidCheckoutScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminBuyers, page: () => const BuyersManagementScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: buyerActivity, page: () => const BuyerActivityScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminOrders, page: () => const OrdersAuditScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: ordersHistory, page: () => const OrdersHistoryScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: profile, page: () => const ProfileScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: businessSettings, page: () => const BusinessSettingsScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminSettings, page: () => const AdminSettingsScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: buyerSettings, page: () => const BuyerSettingsScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminVerifications, page: () => const AdminVerificationsScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: maintenance, page: () => const MaintenanceScreen()),
    GetPage(name: notifications, page: () => const NotificationsScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: adminNotifications, page: () => const AdminNotificationsScreen(), middlewares: [AuthMiddleware()]),
  ];
}