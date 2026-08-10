import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/services/auth_service.dart';
import '../core/utils/theme.dart';
import '../core/widgets/snackbars.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final box = GetStorage();

  // ==============================
  // Logo Floating Animation
  // ==============================
  late AnimationController _logoAnimationController;
  late Animation<Offset> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Smooth Up & Down Motion
    _logoSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.28),
    ).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Continuously move Up ↕ Down
    _logoAnimationController.repeat(reverse: true);
  }

  // ==============================
  // Quick Login Fill
  // ==============================
  void _quickFill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  // ==============================
  // Login
  // ==============================
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppSnackbars.warning(
        title: "Validation Error",
        message: "Please enter both email and password",
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.login(email, password);

    setState(() => _isLoading = false);

    if (result['success']) {
      final role = result['data']['user']['role'];

      AppSnackbars.success(
        title: "Success",
        message:
            "Logged in as ${role[0].toUpperCase()}${role.substring(1)}!",
      );

      if (role == 'admin') {
        Get.offAllNamed('/admin-dashboard');
      } else {
        Get.offAllNamed('/dashboard');
      }
    } else {
      AppSnackbars.error(
        title: "Login Failed",
        message: result['message'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==============================
                // Animated ProductSphere Logo
                // ==============================
                SlideTransition(
                  position: _logoSlideAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_mall_rounded,
                        color: AppTheme.primary,
                        size: 36,
                      ),

                      const SizedBox(width: 10),

                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "Product",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: "Sphere",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ==============================
                // Login Card
                // ==============================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusXl,
                    ),
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==============================
                      // Email
                      // ==============================
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: _inputDecoration(
                          'e.g., buyer@productsphere.com',
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==============================
                      // Password
                      // ==============================
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: _inputDecoration(
                          'Enter your password',
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==============================
                      // Login Button
                      // ==============================
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            disabledBackgroundColor:
                                AppTheme.primary.withValues(
                              alpha: 0.6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==============================
                      // Demo Quick Logins
                      // ==============================
                      const Divider(
                        color: AppTheme.border,
                        height: 20,
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Demo Quick Logins',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickLoginChip(
                            label: 'Admin',
                            color: Colors.blueGrey,
                            email: 'admin@productsphere.com',
                            password: 'adminpassword',
                          ),

                          _quickLoginChip(
                            label: 'Wholesaler',
                            color: AppTheme.primaryDark,
                            email: 'wholesaler@productsphere.com',
                            password: 'wholesalerpassword',
                          ),

                          _quickLoginChip(
                            label: 'Buyer',
                            color: AppTheme.primary,
                            email: 'buyer@productsphere.com',
                            password: 'buyerpassword',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==============================
                // Register
                // ==============================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                    GestureDetector(
                      onTap: () => Get.to(
                        () => RegisterScreen(),
                      ),
                      child: const Text(
                        'Register here',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================
  // Quick Login Chip
  // ==============================
  Widget _quickLoginChip({
    required String label,
    required Color color,
    required String email,
    required String password,
  }) {
    return ActionChip(
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(
        color: color.withValues(alpha: 0.3),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () => _quickFill(
        email,
        password,
      ),
    );
  }

  // ==============================
  // Input Decoration
  // ==============================
  InputDecoration _inputDecoration(
    String hint, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppTheme.textHint,
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF1F4F6),
      suffixIcon: suffix,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppTheme.radiusMd,
        ),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppTheme.radiusMd,
        ),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppTheme.radiusMd,
        ),
        borderSide: const BorderSide(
          color: AppTheme.primary,
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  // ==============================
  // Dispose
  // ==============================
  @override
  void dispose() {
    _logoAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}