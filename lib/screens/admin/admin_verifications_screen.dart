import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_bottom_nav.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/snackbars.dart';

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  List<dynamic> _pendingWholesalers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.fetchPendingWholesalers();
      setState(() {
        _pendingWholesalers = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Fetch verifications error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int userId, String name, String status) async {
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final result = await AuthService.updateBusinessStatus(userId, status);
    Get.back(); // close dialog

    if (result['success']) {
      AppSnackbars.success(
        title: "Action Successful",
        message: "Business '$name' status updated to '$status'.",
      );
      _fetchData();
    } else {
      AppSnackbars.error(
        title: "Action Failed",
        message: result['message'] ?? "Failed to update business status",
      );
    }
  }

  void _showImageDialog(String title, String base64Str) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                )
              ],
            ),
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.memory(
                    base64Decode(base64Str),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded, size: 64, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: 1),
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        foregroundColor: Colors.white,
        title: const Text('Business Verifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _pendingWholesalers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingWholesalers.length,
                    itemBuilder: (context, index) {
                      final business = _pendingWholesalers[index];
                      return _buildVerificationCard(business);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.textLight,
              child: const Icon(Icons.verified_rounded, size: 48, color: AppTheme.secondaryDark),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Pending Applications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'All wholesalers and businesses on the platform are verified.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textThird),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(dynamic business) {
    final int userId = business['id'];
    final String name = business['name'] ?? 'Unnamed Wholesaler';
    final String email = business['email'] ?? 'No email';
    final String phone = business['phone'] ?? 'No phone';
    final String license = business['license_no'] ?? 'N/A';
    final String address = business['business_address'] ?? 'No address provided';

    final String? shopPic = business['shop_picture'];
    final String? cnicFront = business['cnic_front'];
    final String? cnicBack = business['cnic_back'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row header with name & actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  radius: 20,
                  child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                      Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                      onPressed: () => _updateStatus(userId, name, 'approved'),
                      tooltip: 'Approve Business',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 28),
                      onPressed: () => _updateStatus(userId, name, 'rejected'),
                      tooltip: 'Reject Application',
                    ),
                  ],
                )
              ],
            ),
            const Divider(color: AppTheme.border, height: 24),

            // Text Info
            Row(
              children: [
                const Icon(Icons.phone_android_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text('Phone: $phone', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text('License/NTN: $license', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Address: $address',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Document Image Previews
            const Text(
              'Verification Documents (Tap to Zoom)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDocPreviewCard('Shop Picture', shopPic),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDocPreviewCard('CNIC Front', cnicFront),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDocPreviewCard('CNIC Back', cnicBack),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocPreviewCard(String label, String? base64Str) {
    final bool hasImage = base64Str != null && base64Str.isNotEmpty;
    return GestureDetector(
      onTap: hasImage ? () => _showImageDialog(label, base64Str) : null,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.border, width: 0.6),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm - 1),
                child: Image.memory(
                  base64Decode(base64Str),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: AppTheme.textHint),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_not_supported_outlined, color: AppTheme.textHint, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  )
                ],
              ),
      ),
    );
  }
}