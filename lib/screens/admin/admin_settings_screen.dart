import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_bottom_nav.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/snackbars.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // ── Platform Settings controllers ────────────────────────
  final _platformNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  double _commissionPercent = 5;
  double _maxNegotiationRounds = 3;
  bool _maintenanceMode = false;
  bool _allowBuyerReg = true;
  bool _allowWholesalerReg = true;

  // ── Admin Account controllers ─────────────────────────────
  final _adminNameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
    _fetchSettings();
  }

  void _loadAdminData() {
    final user = GetStorage().read('user') ?? {};
    _adminNameCtrl.text = user['name'] ?? '';
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    final result = await SettingsService.fetchSystemSettings();
    if (result['success'] == true) {
      final data = result['data'] as Map<String, String>;
      setState(() {
        _platformNameCtrl.text = data['platform_name'] ?? 'Product Sphere';
        _contactEmailCtrl.text = data['contact_email'] ?? '';
        _commissionPercent = double.tryParse(data['commission_percent'] ?? '5') ?? 5;
        _maxNegotiationRounds = double.tryParse(data['max_negotiation_rounds'] ?? '3') ?? 3;
        _maintenanceMode = data['maintenance_mode'] == 'true';
        _allowBuyerReg = data['allow_buyer_registration'] != 'false';
        _allowWholesalerReg = data['allow_wholesaler_registration'] != 'false';
      });
    } else {
      AppSnackbars.error(title: 'Load Failed', message: result['message'] ?? 'Could not load settings');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _savePlatformSettings() async {
    setState(() => _isSaving = true);
    final result = await SettingsService.saveSystemSettings({
      'platform_name': _platformNameCtrl.text.trim(),
      'contact_email': _contactEmailCtrl.text.trim(),
      'commission_percent': _commissionPercent.round().toString(),
      'max_negotiation_rounds': _maxNegotiationRounds.round().toString(),
      'maintenance_mode': _maintenanceMode.toString(),
      'allow_buyer_registration': _allowBuyerReg.toString(),
      'allow_wholesaler_registration': _allowWholesalerReg.toString(),
    });
    setState(() => _isSaving = false);
    if (result['success'] == true) {
      AppSnackbars.success(title: 'Settings Saved', message: 'Platform settings updated successfully.');
    } else {
      AppSnackbars.error(title: 'Save Failed', message: result['message'] ?? 'Could not save settings');
    }
  }

  Future<void> _saveAccountSettings() async {
    final name = _adminNameCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;
    final currentPass = _currentPassCtrl.text;

    if (newPass.isNotEmpty && newPass != confirmPass) {
      AppSnackbars.error(title: 'Validation Error', message: 'New passwords do not match.');
      return;
    }

    setState(() => _isSaving = true);

    // Update profile name
    if (name.isNotEmpty) {
      final profileResult = await SettingsService.updateProfile(name: name);
      if (profileResult['success'] == true) {
        final box = GetStorage();
        final user = Map<String, dynamic>.from(box.read('user') ?? {});
        user['name'] = name;
        box.write('user', user);
      }
    }

    // Change password if provided
    if (newPass.isNotEmpty) {
      final passResult = await SettingsService.changePassword(
        currentPassword: currentPass,
        newPassword: newPass,
      );
      if (passResult['success'] != true) {
        setState(() => _isSaving = false);
        AppSnackbars.error(title: 'Password Error', message: passResult['message'] ?? 'Failed to change password');
        return;
      }
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    }

    setState(() => _isSaving = false);
    AppSnackbars.success(title: 'Account Updated', message: 'Your account settings have been saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        foregroundColor: Colors.white,
        title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _tabController.index == 0 ? _savePlatformSettings : _saveAccountSettings,
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
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Platform'),
            Tab(icon: Icon(Icons.manage_accounts_rounded, size: 18), text: 'My Account'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlatformTab(),
                _buildAccountTab(),
              ],
            ),
    );
  }

  // ── PLATFORM SETTINGS TAB ─────────────────────────────────
  Widget _buildPlatformTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            icon: Icons.storefront_outlined,
            title: 'Platform Identity',
            children: [
              _fieldLabel('Platform Name'),
              const SizedBox(height: 6),
              _textField(controller: _platformNameCtrl, hint: 'e.g., Product Sphere'),
              const SizedBox(height: 14),
              _fieldLabel('Support / Contact Email'),
              const SizedBox(height: 6),
              _textField(controller: _contactEmailCtrl, hint: 'e.g., support@productsphere.com', keyboardType: TextInputType.emailAddress),
            ],
          ),
          const SizedBox(height: 16),

          _sectionCard(
            icon: Icons.percent_rounded,
            title: 'Marketplace Rules',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldLabel('Platform Commission'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.textLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${_commissionPercent.round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _commissionPercent,
                min: 0,
                max: 20,
                divisions: 20,
                activeColor: AppTheme.secondary,
                inactiveColor: AppTheme.border,
                onChanged: (v) => setState(() => _commissionPercent = v),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldLabel('Max Negotiation Rounds'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.textLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${_maxNegotiationRounds.round()} rounds',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxNegotiationRounds,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppTheme.secondary,
                inactiveColor: AppTheme.border,
                onChanged: (v) => setState(() => _maxNegotiationRounds = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionCard(
            icon: Icons.toggle_on_rounded,
            title: 'Registration Controls',
            children: [
              _switchTile(
                label: 'Allow Buyer Registration',
                subtitle: 'New buyers can sign up on the platform',
                value: _allowBuyerReg,
                onChanged: (v) => setState(() => _allowBuyerReg = v),
              ),
              const Divider(color: AppTheme.border, height: 20),
              _switchTile(
                label: 'Allow Wholesaler Registration',
                subtitle: 'New wholesalers can apply to join',
                value: _allowWholesalerReg,
                onChanged: (v) => setState(() => _allowWholesalerReg = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Maintenance mode gets its own card with a warning style
          Container(
            decoration: BoxDecoration(
              color: _maintenanceMode ? const Color(0xFFFFF3E0) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: _maintenanceMode ? Colors.orange.shade300 : AppTheme.border,
                width: _maintenanceMode ? 1.5 : 1,
              ),
              boxShadow: [AppTheme.cardShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.construction_rounded,
                          color: _maintenanceMode ? Colors.orange.shade700 : AppTheme.textThird, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Maintenance Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _maintenanceMode ? Colors.orange.shade800 : AppTheme.secondaryDark,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _maintenanceMode,
                        activeThumbColor: Colors.orange.shade700,
                        onChanged: (v) => setState(() => _maintenanceMode = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _maintenanceMode
                        ? '⚠️  Platform is currently offline for users. Only admins can log in.'
                        : 'When enabled, the platform will be inaccessible to buyers and sellers.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _maintenanceMode ? Colors.orange.shade700 : AppTheme.secondary,
                    ),
                  ),
                ],
              )
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePlatformSettings,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Platform Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryDark,
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

  // ── ACCOUNT TAB ───────────────────────────────────────────
  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Admin Profile',
            children: [
              _fieldLabel('Display Name'),
              const SizedBox(height: 6),
              _textField(controller: _adminNameCtrl, hint: 'Admin name'),
            ],
          ),
          const SizedBox(height: 16),

          _sectionCard(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            children: [
              _fieldLabel('Current Password'),
              const SizedBox(height: 6),
              _passwordField(
                controller: _currentPassCtrl,
                hint: 'Enter current password',
                obscure: _obscureCurrent,
                toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 14),
              _fieldLabel('New Password'),
              const SizedBox(height: 6),
              _passwordField(
                controller: _newPassCtrl,
                hint: 'Min. 6 characters',
                obscure: _obscureNew,
                toggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Confirm New Password'),
              const SizedBox(height: 6),
              _passwordField(
                controller: _confirmPassCtrl,
                hint: 'Repeat new password',
                obscure: _obscureConfirm,
                toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAccountSettings,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Account Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryDark,
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
            Icon(icon, size: 18, color: AppTheme.secondaryDark),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.secondaryDark)),
          ]),
          const Divider(color: AppTheme.border, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _switchTile({required String label, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textThird)),
            ],
          ),
        ),
        Switch(activeThumbColor: AppTheme.secondary, value: value, onChanged: onChanged),
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
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5)),
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
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppTheme.secondary), onPressed: toggle),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  @override
  void dispose() {
    _tabController.dispose();
    _platformNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _adminNameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}