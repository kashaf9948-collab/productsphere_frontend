import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/product_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/admin_bottom_nav.dart';
import '../../core/widgets/snackbars.dart';
import '../../core/widgets/dialogs.dart';

class BuyersManagementScreen extends StatefulWidget {
  const BuyersManagementScreen({Key? key}) : super(key: key);

  @override
  State<BuyersManagementScreen> createState() => _BuyersManagementScreenState();
}

class _BuyersManagementScreenState extends State<BuyersManagementScreen> {
  bool _isLoading = false;
  List<dynamic> _buyers = [];

  @override
  void initState() {
    super.initState();
    _fetchBuyers();
  }

  Future<void> _fetchBuyers() async {
    setState(() => _isLoading = true);
    final list = await ProductService.fetchAdminBuyers();
    setState(() {
      _buyers = list;
      _isLoading = false;
    });
  }

  Future<void> _toggleAccess(dynamic buyer) async {
    final int buyerId = buyer['id'];
    final String currentStatus = buyer['status'] ?? 'approved';
    final String newStatus = currentStatus == 'approved' ? 'suspended' : 'approved';
    final String name = buyer['name'] ?? 'Buyer';

    final confirm = await showConfirmDialog(
      title: newStatus == 'suspended' ? 'Revoke Access' : 'Restore Access',
      content: newStatus == 'suspended' 
          ? 'Are you sure you want to revoke marketplace access for "$name"?'
          : 'Are you sure you want to restore marketplace access for "$name"?',
      confirmColor: newStatus == 'suspended' ? AppTheme.expired : AppTheme.active,
    );

    if (!confirm) return;

    showLoadingDialog(color: AppTheme.primary);
    final result = await AuthService.updateBusinessStatus(buyerId, newStatus);
    Get.back(); // Close loading dialog

    if (result['success']) {
      AppSnackbars.success(
        title: "Status Updated",
        message: "Marketplace access for '$name' has been ${newStatus == 'suspended' ? 'revoked' : 'restored'}.",
      );
      _fetchBuyers();
    } else {
      AppSnackbars.error(
        title: "Action Failed",
        message: result['message'] ?? "Failed to update access status.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: 2), // Maps to Users/Buyers tab
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Registered Buyers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchBuyers,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : _buyers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No Registered Buyers',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Registered buyer accounts will appear here.',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _buyers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final buyer = _buyers[index];
                      final name = buyer['name'] ?? 'Unnamed Buyer';
                      final email = buyer['email'] ?? 'N/A';
                      final phone = buyer['phone'] ?? 'N/A';
                      final status = buyer['status'] ?? 'approved';
                      final isRevoked = status == 'suspended' || status == 'revoked';

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isRevoked ? AppTheme.expiredLight : AppTheme.activeLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isRevoked ? 'REVOKED' : 'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold, 
                                        color: isRevoked ? AppTheme.expired : AppTheme.active,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: AppTheme.border),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(phone, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // View Activity
                                  OutlinedButton.icon(
                                    onPressed: () => Get.toNamed('/buyer-activity', arguments: buyer),
                                    icon: const Icon(Icons.analytics_outlined, size: 16),
                                    label: const Text('View Activity'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                      minimumSize: const Size(120, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Revoke / Restore Access
                                  ElevatedButton.icon(
                                    onPressed: () => _toggleAccess(buyer),
                                    icon: Icon(
                                      isRevoked ? Icons.check_circle_outline : Icons.block_flipped, 
                                      size: 16,
                                    ),
                                    label: Text(isRevoked ? 'Restore Access' : 'Revoke Access'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isRevoked ? AppTheme.active : AppTheme.expired,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(130, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}