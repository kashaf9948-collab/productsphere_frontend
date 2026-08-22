import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/snackbars.dart';
import '../../core/widgets/wholesaler_bottom_nav.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();
  late Map<String, dynamic> _user;
  bool _isSaving = false;

  // Editable text controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _licenseCtrl;
  late TextEditingController _addressCtrl;

  // Document images — can be either pre-existing base64 or newly picked bytes
  Uint8List? _shopPicBytes;
  Uint8List? _cnicFrontBytes;
  Uint8List? _cnicBackBytes;

  // Existing base64 previews from storage
  String? _shopPicBase64;
  String? _cnicFrontBase64;
  String? _cnicBackBase64;

  // Account tab controllers
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Notification preferences
  bool _notifyOrders = true;
  bool _notifyNegotiations = true;
  bool _notifyPromotions = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final userData = box.read('user');
    _user = userData is Map ? Map<String, dynamic>.from(userData) : {};

    _nameCtrl = TextEditingController(text: _user['name'] ?? '');
    _phoneCtrl = TextEditingController(text: _user['phone'] ?? '');
    _licenseCtrl = TextEditingController(text: _user['license_no'] ?? '');
    _addressCtrl = TextEditingController(text: _user['business_address'] ?? '');

    _shopPicBase64 = _user['shop_picture'];
    _cnicFrontBase64 = _user['cnic_front'];
    _cnicBackBase64 = _user['cnic_back'];

    _notifyOrders = box.read('pref_notify_orders') ?? true;
    _notifyNegotiations = box.read('pref_notify_negotiations') ?? true;
    _notifyPromotions = box.read('pref_notify_promotions') ?? false;
  }

  Future<void> _pickImage({required String label, required Function(Uint8List) onPicked}) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Update $label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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

  void _saveSettings() {
    // Save locally to GetStorage (backend update would require a separate API endpoint)
    final updatedUser = Map<String, dynamic>.from(_user);
    updatedUser['name'] = _nameCtrl.text.trim();
    updatedUser['phone'] = _phoneCtrl.text.trim();
    updatedUser['license_no'] = _licenseCtrl.text.trim();
    updatedUser['business_address'] = _addressCtrl.text.trim();

    // Update images if changed
    if (_shopPicBytes != null) {
      updatedUser['shop_picture'] = base64Encode(_shopPicBytes!);
    }
    if (_cnicFrontBytes != null) {
      updatedUser['cnic_front'] = base64Encode(_cnicFrontBytes!);
    }
    if (_cnicBackBytes != null) {
      updatedUser['cnic_back'] = base64Encode(_cnicBackBytes!);
    }

    box.write('user', updatedUser);
    setState(() {
      _user = updatedUser;
      _shopPicBase64 = updatedUser['shop_picture'];
      _cnicFrontBase64 = updatedUser['cnic_front'];
      _cnicBackBase64 = updatedUser['cnic_back'];
    });

    AppSnackbars.success(title: 'Settings Saved', message: 'Business profile updated successfully.');
  }

  Future<void> _saveAccountSettings() async {
    if (_newPassCtrl.text.isNotEmpty && _newPassCtrl.text != _confirmPassCtrl.text) {
      AppSnackbars.error(title: 'Error', message: 'Passwords do not match.');
      return;
    }
    setState(() => _isSaving = true);
    box.write('pref_notify_orders', _notifyOrders);
    box.write('pref_notify_negotiations', _notifyNegotiations);
    box.write('pref_notify_promotions', _notifyPromotions);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSaving = false);
    AppSnackbars.success(title: 'Account Saved', message: 'Preferences updated successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final status = _user['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const WholesalerBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _tabController.index == 0 ? _saveSettings : _saveAccountSettings,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.business_outlined, size: 18), text: 'Business'),
            Tab(icon: Icon(Icons.manage_accounts_rounded, size: 18), text: 'Account'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessTab(status),
          _buildAccountTab(),
        ],
      ),
    );
  }

  Widget _buildBusinessTab(String status) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: status == 'approved' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: status == 'approved' ? Colors.green.shade300 : Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(status == 'approved' ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                        color: status == 'approved' ? Colors.green.shade700 : Colors.orange.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status == 'approved' ? 'Account Verified' : 'Pending Admin Verification',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: status == 'approved' ? Colors.green.shade800 : Colors.orange.shade800),
                          ),
                          Text(
                            status == 'approved'
                                ? 'Your business is verified and live on the platform.'
                                : 'Your documents are under admin review. You will be notified.',
                            style: TextStyle(fontSize: 11, color: status == 'approved' ? Colors.green.shade700 : Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Business Info
              _sectionHeader('Business Information', Icons.business_outlined),
              const SizedBox(height: 12),
              _label('Business / Shop Name'),
              const SizedBox(height: 6),
              _textField(controller: _nameCtrl, hint: 'e.g., Al-Madina Wholesalers'),
              const SizedBox(height: 14),
              _label('Phone Number'),
              const SizedBox(height: 6),
              _textField(controller: _phoneCtrl, hint: 'e.g., 03001234567', keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _label('License / NTN Number'),
              const SizedBox(height: 6),
              _textField(controller: _licenseCtrl, hint: 'e.g., TX-123456-A'),
              const SizedBox(height: 14),
              _label('Business Address'),
              const SizedBox(height: 6),
              _textField(controller: _addressCtrl, hint: 'e.g., Suite 10, Trade Center, Lahore', maxLines: 2),
              const SizedBox(height: 24),

            // Documents Section
            _sectionHeader('Verification Documents', Icons.description_outlined),
              const SizedBox(height: 4),
              const Text('Tap any document to update it.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 14),

              _label('Shop / Business Picture'),
              const SizedBox(height: 8),
              _docTile(
                label: 'Shop Picture',
                icon: Icons.storefront_outlined,
                newBytes: _shopPicBytes,
                existingBase64: _shopPicBase64,
                onTap: () => _pickImage(label: 'Shop Picture', onPicked: (bytes) => setState(() => _shopPicBytes = bytes)),
              ),
              const SizedBox(height: 14),

              _label('CNIC Front Side'),
              const SizedBox(height: 8),
              _docTile(
                label: 'CNIC Front',
                icon: Icons.credit_card_rounded,
                newBytes: _cnicFrontBytes,
                existingBase64: _cnicFrontBase64,
                onTap: () => _pickImage(label: 'CNIC Front', onPicked: (bytes) => setState(() => _cnicFrontBytes = bytes)),
              ),
              const SizedBox(height: 14),

              _label('CNIC Back Side'),
              const SizedBox(height: 8),
              _docTile(
                label: 'CNIC Back',
                icon: Icons.credit_card_outlined,
                newBytes: _cnicBackBytes,
                existingBase64: _cnicBackBase64,
                onTap: () => _pickImage(label: 'CNIC Back', onPicked: (bytes) => setState(() => _cnicBackBytes = bytes)),
              ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd))),
                child: const Text('Save Business Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // Password Section
          _sectionHeader('Change Password', Icons.lock_outline_rounded),
          const SizedBox(height: 12),
          _label('Current Password'),
          const SizedBox(height: 6),
          _passwordField(controller: _currentPassCtrl, hint: 'Enter current password', obscure: _obscureCurrent, toggle: () => setState(() => _obscureCurrent = !_obscureCurrent)),
          const SizedBox(height: 14),
          _label('New Password'),
          const SizedBox(height: 6),
          _passwordField(controller: _newPassCtrl, hint: 'Min. 6 characters', obscure: _obscureNew, toggle: () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 14),
          _label('Confirm New Password'),
          const SizedBox(height: 6),
          _passwordField(controller: _confirmPassCtrl, hint: 'Repeat new password', obscure: _obscureConfirm, toggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 24),

          // Notification Preferences
          _sectionHeader('Notification Preferences', Icons.notifications_outlined),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [AppTheme.cardShadow],
            ),
            child: Column(
              children: [
                _prefTile(
                  label: 'Order Updates',
                  subtitle: 'Notify me on order status changes',
                  icon: Icons.shopping_bag_outlined,
                  value: _notifyOrders,
                  onChanged: (v) => setState(() => _notifyOrders = v),
                ),
                const Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16),
                _prefTile(
                  label: 'Negotiation Activity',
                  subtitle: 'Alerts for bids and counter-offers',
                  icon: Icons.gavel_rounded,
                  value: _notifyNegotiations,
                  onChanged: (v) => setState(() => _notifyNegotiations = v),
                ),
                const Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16),
                _prefTile(
                  label: 'Promotions & Deals',
                  subtitle: 'Platform offers and announcements',
                  icon: Icons.local_offer_outlined,
                  value: _notifyPromotions,
                  onChanged: (v) => setState(() => _notifyPromotions = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAccountSettings,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd))),
              child: const Text('Save Account Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _prefTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      trailing: Switch(activeThumbColor: AppTheme.primary, value: value, onChanged: onChanged),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppTheme.textSecondary),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _docTile({
    required String label,
    required IconData icon,
    required Uint8List? newBytes,
    required String? existingBase64,
    required VoidCallback onTap,
  }) {
    final bool hasImage = newBytes != null || (existingBase64 != null && existingBase64.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F6),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: hasImage ? AppTheme.primary : Colors.grey.shade300, width: hasImage ? 1.5 : 1),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1),
                    child: newBytes != null
                        ? Image.memory(newBytes, fit: BoxFit.cover)
                        : Image.memory(base64Decode(existingBase64!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: AppTheme.textSecondary))),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: CircleAvatar(radius: 14, backgroundColor: AppTheme.primary, child: const Icon(Icons.check_rounded, size: 16, color: Colors.white)),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusMd - 1))),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: const Text('Tap to update', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppTheme.textSecondary, size: 30),
                  const SizedBox(height: 8),
                  Text('Tap to upload $label', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('Camera or Gallery', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));

  Widget _textField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _addressCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}