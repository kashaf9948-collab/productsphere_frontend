import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/auth_service.dart';
import '../core/utils/theme.dart';
import '../core/widgets/snackbars.dart';
import 'package:get_storage/get_storage.dart';

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
  String _selectedRole = 'Buyer';
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Document images (stored as base64 bytes)
  Uint8List? _shopPictureBytes;
  Uint8List? _cnicFrontBytes;
  Uint8List? _cnicBackBytes;

  final ImagePicker _picker = ImagePicker();
  final List<String> _genderOptions = ['Male', 'Female'];
  List<String> _roleOptions = ['Buyer', 'Wholesaler'];

  @override
  void initState() {
    super.initState();
    final box = GetStorage();
    final settings = box.read('public_settings') ?? {};
    final allowBuyer = settings['allow_buyer_registration'] != 'false';
    final allowWholesaler = settings['allow_wholesaler_registration'] != 'false';

    _roleOptions = [];
    if (allowBuyer) _roleOptions.add('Buyer');
    if (allowWholesaler) _roleOptions.add('Wholesaler');

    if (_roleOptions.isNotEmpty) {
      _selectedRole = _roleOptions.first;
    } else {
      _selectedRole = '';
    }
  }

  Future<void> _pickImage({
    required String label,
    required Function(Uint8List) onPicked,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Upload $label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.primary, child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  onPicked(bytes);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF546E7A), child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 20)),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from photos'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  onPicked(bytes);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String? _bytesToBase64(Uint8List? bytes) {
    if (bytes == null) return null;
    return base64Encode(bytes);
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final license = _licenseController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      AppSnackbars.warning(title: "Validation Error", message: "Please fill in all the required fields");
      return;
    }

    if (_selectedRole == 'Wholesaler') {
      if (license.isEmpty || address.isEmpty) {
        AppSnackbars.warning(title: "Validation Error", message: "Please fill in your license/NTN and business address");
        return;
      }
      if (_shopPictureBytes == null) {
        AppSnackbars.warning(title: "Validation Error", message: "Please upload your shop/business picture");
        return;
      }
      if (_cnicFrontBytes == null || _cnicBackBytes == null) {
        AppSnackbars.warning(title: "Validation Error", message: "Please upload both CNIC front and back");
        return;
      }
    }

    if (password.length < 6) {
      AppSnackbars.warning(title: "Validation Error", message: "Password must be at least 6 characters long");
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
      AppSnackbars.success(
        title: "Registration Successful",
        message: result['message'] ?? "Account created successfully!",
      );
    } else {
      AppSnackbars.error(title: "Registration Failed", message: result['message']);
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
        child: _roleOptions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block_rounded, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Registration Disabled',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'New registrations are temporarily closed by the platform administrator.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Register to explore Product Sphere B2B market', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 28),

              // Full Name
              _label('Full Name / Business Name *'),
              const SizedBox(height: 8),
              _textField(controller: _nameController, hint: 'e.g., Al-Madina Wholesalers'),
              const SizedBox(height: 18),

              // Phone Number
              _label('Phone Number *'),
              const SizedBox(height: 8),
              _textField(controller: _phoneController, hint: 'e.g., 03001234567', keyboardType: TextInputType.phone),
              const SizedBox(height: 18),

              // Gender & Role Selection
              Row(
                children: [
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
                              items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (value) => setState(() => _selectedGender = value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
                              items: _roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
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

              // Wholesaler-specific fields
              if (_selectedRole == 'Wholesaler') ...[
                _label('Business License / NTN Number *'),
                const SizedBox(height: 8),
                _textField(controller: _licenseController, hint: 'e.g., TX-123456-A'),
                const SizedBox(height: 18),
                _label('Business Address *'),
                const SizedBox(height: 8),
                _textField(controller: _addressController, hint: 'e.g., Suite 10, Trade Center, Lahore'),
                const SizedBox(height: 24),

                // Documents Section Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.description_outlined, color: AppTheme.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Business Verification Documents',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'These documents will be reviewed by admin to verify your business.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Shop Picture
                _label('Shop / Business Picture *'),
                const SizedBox(height: 8),
                _imagePickerTile(
                  label: 'Shop Picture',
                  icon: Icons.storefront_outlined,
                  bytes: _shopPictureBytes,
                  onTap: () => _pickImage(label: 'Shop Picture', onPicked: (bytes) => setState(() => _shopPictureBytes = bytes)),
                ),
                const SizedBox(height: 16),

                // CNIC Front
                _label('CNIC Front Side *'),
                const SizedBox(height: 8),
                _imagePickerTile(
                  label: 'CNIC Front',
                  icon: Icons.credit_card_rounded,
                  bytes: _cnicFrontBytes,
                  onTap: () => _pickImage(label: 'CNIC Front', onPicked: (bytes) => setState(() => _cnicFrontBytes = bytes)),
                ),
                const SizedBox(height: 16),

                // CNIC Back
                _label('CNIC Back Side *'),
                const SizedBox(height: 8),
                _imagePickerTile(
                  label: 'CNIC Back',
                  icon: Icons.credit_card_outlined,
                  bytes: _cnicBackBytes,
                  onTap: () => _pickImage(label: 'CNIC Back', onPicked: (bytes) => setState(() => _cnicBackBytes = bytes)),
                ),
                const SizedBox(height: 18),
              ],

              // Email Address
              _label('Email Address *'),
              const SizedBox(height: 8),
              _textField(controller: _emailController, hint: 'e.g., business@example.com', keyboardType: TextInputType.emailAddress),
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
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text('Login here', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
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

  Widget _imagePickerTile({
    required String label,
    required IconData icon,
    required Uint8List? bytes,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F6),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: bytes != null ? AppTheme.primary : Colors.grey.shade300,
            width: bytes != null ? 1.5 : 1,
          ),
        ),
        child: bytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary,
                      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusMd - 1)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: const Text('Tap to change', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppTheme.textSecondary, size: 28),
                  const SizedBox(height: 8),
                  Text('Tap to upload $label', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('Camera or Gallery', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F6), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: child,
    );
  }

  Widget _textField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text}) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF1F4F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
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