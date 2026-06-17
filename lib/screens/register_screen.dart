import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/auth_service.dart';
import '../core/utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGender = 'Male';
  String _selectedRole = 'Buyer'; // default role
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _roleOptions = ['Buyer', 'Wholesaler'];

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final license = _licenseController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please fill in all the required fields",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedRole == 'Wholesaler' && (license.isEmpty || address.isEmpty)) {
      Get.snackbar(
        "Validation Error",
        "Please fill in your license/NTN and business address",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        "Validation Error",
        "Password must be at least 6 characters long",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
      phone: phone,
      gender: _selectedGender ?? 'male',
      licenseNo: _selectedRole == 'Wholesaler' ? license : null,
      businessAddress: _selectedRole == 'Wholesaler' ? address : null,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      Get.offAllNamed('/login');
      Get.snackbar(
        "Registration Successful",
        result['message'] ?? "Account created successfully!",
        backgroundColor: AppTheme.activeLight,
        colorText: AppTheme.active,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        "Registration Failed",
        result['message'],
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Register to explore Product Sphere B2B market',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Full Name
              _label('Full Name / Business Name *'),
              const SizedBox(height: 8),
              _textField(controller: _nameController, hint: 'e.g., Al-Madina Wholesalers'),
              const SizedBox(height: 18),

              // Phone Number
              _label('Phone Number *'),
              const SizedBox(height: 8),
              _textField(
                controller: _phoneController,
                hint: 'e.g., 03001234567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),

              // Gender & Role Selection
              Row(
                children: [
                  // Gender
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Gender'),
                        const SizedBox(height: 8),
                        _dropdownContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: _genderOptions
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedGender = value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Business Role *'),
                        const SizedBox(height: 8),
                        _dropdownContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              items: _roleOptions
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedRole = value!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Wholesaler-specific fields (License & Address)
              if (_selectedRole == 'Wholesaler') ...[
                _label('Business License / NTN Number *'),
                const SizedBox(height: 8),
                _textField(controller: _licenseController, hint: 'e.g., TX-123456-A'),
                const SizedBox(height: 18),
                _label('Business Address *'),
                const SizedBox(height: 8),
                _textField(controller: _addressController, hint: 'e.g., Suite 10, Trade Center, Lahore'),
                const SizedBox(height: 18),
              ],

              // Email Address
              _label('Email Address *'),
              const SizedBox(height: 8),
              _textField(
                controller: _emailController,
                hint: 'e.g., business@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // Password
              _label('Password (Min. 6 Characters) *'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF1F4F6),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Redirect to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      'Login here',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F6),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF1F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
