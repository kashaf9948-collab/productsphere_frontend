import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/client_bottom_nav.dart';
import '../../core/widgets/snackbars.dart';

class BuyerSettingsScreen extends StatefulWidget {
  const BuyerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BuyerSettingsScreen> createState() => _BuyerSettingsScreenState();
}

class _BuyerSettingsScreenState extends State<BuyerSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _box = GetStorage();
  bool _isSaving = false;

  // ── Profile ─────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedGender = 'male';

  // ── Security ─────────────────────────────────────────────
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ── Preferences (local only) ──────────────────────────────
  bool _notifyOrders = true;
  bool _notifyNegotiations = true;
  bool _notifyPromotions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadPreferences();
  }

  void _loadUserData() {
    final user = _box.read('user') ?? {};
    _nameCtrl.text = user['name'] ?? '';
    _phoneCtrl.text = user['phone'] ?? '';
    final gender = (user['gender'] ?? 'male').toString().toLowerCase();
    _selectedGender = (gender == 'female') ? 'female' : 'male';
  }

  void _loadPreferences() {
    _notifyOrders = _box.read('pref_notify_orders') ?? true;
    _notifyNegotiations = _box.read('pref_notify_negotiations') ?? true;
    _notifyPromotions = _box.read('pref_notify_promotions') ?? false;
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackbars.error(title: 'Validation', message: 'Name cannot be empty.');
      return;
    }
    setState(() => _isSaving = true);
    final result = await SettingsService.updateProfile(
      name: name,
      phone: phone,
      gender: _selectedGender,
    );
    setState(() => _isSaving = false);
    if (result['success'] == true) {
      AppSnackbars.success(title: 'Profile Updated', message: 'Your profile has been saved.');
    } else {
      AppSnackbars.error(title: 'Update Failed', message: result['message'] ?? 'Could not update profile');
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      AppSnackbars.error(title: 'Validation', message: 'Please fill all password fields.');
      return;
    }
    if (newPass != confirm) {
      AppSnackbars.error(title: 'Validation', message: 'New passwords do not match.');
      return;
    }
    if (newPass.length < 6) {
      AppSnackbars.error(title: 'Validation', message: 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _isSaving = true);
    final result = await SettingsService.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      AppSnackbars.success(title: 'Password Changed', message: 'Your password has been updated.');
    } else {
      AppSnackbars.error(title: 'Change Failed', message: result['message'] ?? 'Could not change password');
    }
  }

  void _savePreferences() {
    _box.write('pref_notify_orders', _notifyOrders);
    _box.write('pref_notify_negotiations', _notifyNegotiations);
    _box.write('pref_notify_promotions', _notifyPromotions);
    AppSnackbars.success(title: 'Preferences Saved', message: 'Notification preferences updated.');
  }

  @override
  Widget build(BuildContext context) {
    final user = _box.read('user') ?? {};
    final String name = user['name'] ?? 'Buyer';
    final String email = user['email'] ?? '';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const ClientBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.person_outline_rounded, size: 18), text: 'Profile'),
            Tab(icon: Icon(Icons.lock_outline_rounded, size: 18), text: 'Security'),
            Tab(icon: Icon(Icons.notifications_outlined, size: 18), text: 'Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(name, email, initial),
          _buildSecurityTab(),
          _buildPreferencesTab(),
        ],
      ),
    );
  }

  // ── PROFILE TAB ───────────────────────────────────────────
  Widget _buildProfileTab(String name, String email, String initial) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [AppTheme.cardShadow],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionCard(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            children: [
              _fieldLabel('Full Name'),
              const SizedBox(height: 6),
              _textField(controller: _nameCtrl, hint: 'Your full name'),
              const SizedBox(height: 14),
              _fieldLabel('Phone Number'),
              const SizedBox(height: 6),
              _textField(controller: _phoneCtrl, hint: 'e.g., 03001234567', keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _fieldLabel('Gender'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _genderChip('Male', 'male', Icons.male_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _genderChip('Female', 'female', Icons.female_rounded)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _genderChip(String label, String value, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SECURITY TAB ──────────────────────────────────────────
  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _sectionCard(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            children: [
              _fieldLabel('Current Password'),
              const SizedBox(height: 6),
              _passwordField(controller: _currentPassCtrl, hint: 'Enter current password', obscure: _obscureCurrent, toggle: () => setState(() => _obscureCurrent = !_obscureCurrent)),
              const SizedBox(height: 14),
              _fieldLabel('New Password'),
              const SizedBox(height: 6),
              _passwordField(controller: _newPassCtrl, hint: 'Min. 6 characters', obscure: _obscureNew, toggle: () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 14),
              _fieldLabel('Confirm New Password'),
              const SizedBox(height: 6),
              _passwordField(controller: _confirmPassCtrl, hint: 'Repeat new password', obscure: _obscureConfirm, toggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use at least 6 characters with a mix of letters and numbers for a strong password.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _changePassword,
              icon: const Icon(Icons.lock_reset_rounded, size: 18),
              label: const Text('Update Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── PREFERENCES TAB ───────────────────────────────────────
  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _sectionCard(
            icon: Icons.notifications_outlined,
            title: 'Notification Preferences',
            children: [
              _switchTile(
                label: 'Order Updates',
                subtitle: 'Get notified about your order status changes',
                value: _notifyOrders,
                icon: Icons.shopping_bag_outlined,
                onChanged: (v) => setState(() => _notifyOrders = v),
              ),
              const Divider(color: AppTheme.border, height: 20),
              _switchTile(
                label: 'Negotiation Activity',
                subtitle: 'Alerts for bids, counter-offers, and approvals',
                value: _notifyNegotiations,
                icon: Icons.gavel_rounded,
                onChanged: (v) => setState(() => _notifyNegotiations = v),
              ),
              const Divider(color: AppTheme.border, height: 20),
              _switchTile(
                label: 'Promotions & Deals',
                subtitle: 'Exclusive offers and discount announcements',
                value: _notifyPromotions,
                icon: Icons.local_offer_outlined,
                onChanged: (v) => setState(() => _notifyPromotions = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _savePreferences,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Preferences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────
  Widget _sectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ]),
          const Divider(color: AppTheme.border, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _switchTile({required String label, required String subtitle, required bool value, required IconData icon, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        Switch(activeColor: AppTheme.primary, value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary));

  Widget _textField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text}) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  Widget _passwordField({required TextEditingController controller, required String hint, required bool obscure, required VoidCallback toggle}) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppTheme.textSecondary), onPressed: toggle),
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
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}