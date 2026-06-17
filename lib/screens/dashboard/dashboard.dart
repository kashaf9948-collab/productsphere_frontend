import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/wholesaler_drawer.dart';
import '../../core/widgets/wholesaler_bottom_nav.dart';
import '../../core/widgets/client_drawer.dart';
import '../../core/widgets/client_bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  void _logout() {
    AuthService.logout();
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final user = box.read('user') ?? {};
    final String name = user['name'] ?? 'User';
    final String email = user['email'] ?? 'No email';
    final String role = box.read('role') ?? 'buyer'; // default to buyer
    final String phone = user['phone'] ?? 'N/A';

    final isWholesaler = role.toLowerCase() == 'wholesaler';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isWholesaler ? const WholesalerDrawer() : const ClientDrawer(),
      bottomNavigationBar: isWholesaler
          ? const WholesalerBottomNav(activeIndex: 0)
          : const ClientBottomNav(activeIndex: 0),
      appBar: AppBar(
        backgroundColor: isWholesaler ? Colors.indigo.shade700 : AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          isWholesaler ? 'Wholesaler Portal' : 'Buyer Marketplace',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- WELCOME CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF009688)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isWholesaler ? 'Role: Wholesaler / Donor' : 'Role: Buyer / Retailer',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          email,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                        Text(
                          phone,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- ROLE-SPECIFIC VIEWS ---
              if (isWholesaler)
                _buildWholesalerDashboard(context)
              else
                _buildBuyerDashboard(context),
            ],
          ),
        ),
      ),
    );
  }

  // Wholesaler / Seller UI view
  Widget _buildWholesalerDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Wholesaler Stats Row
        Row(
          children: [
            Expanded(
              child: _statItem(
                title: 'Total Listings',
                value: '14',
                color: Colors.teal,
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statItem(
                title: 'Pending Offers',
                value: '5',
                color: Colors.orange,
                icon: Icons.gavel_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statItem(
                title: 'Active Orders',
                value: '3',
                color: Colors.blue,
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statItem(
                title: 'Completed Deals',
                value: '38',
                color: Colors.green,
                icon: Icons.handshake_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Action Buttons
        _actionCard(
          icon: Icons.add_photo_alternate_outlined,
          title: 'Add New Product Listing',
          subtitle: 'Upload product details, images, and bulk prices.',
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        _actionCard(
          icon: Icons.gavel_rounded,
          title: 'Manage Price Negotiations',
          subtitle: 'Review proposed prices and counter-offers from buyers.',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _actionCard(
          icon: Icons.assignment_outlined,
          title: 'Incoming Purchase Orders',
          subtitle: 'View placed orders and manage shipping status.',
          color: Colors.blue,
        ),
      ],
    );
  }

  // Buyer / Retailer UI view
  Widget _buildBuyerDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Categories list
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _categoryChip('👕 Clothing', Colors.purple),
              _categoryChip('👟 Shoes', Colors.blue),
              _categoryChip('🧴 Perfumes', Colors.pink),
              _categoryChip('🔌 Electronics', Colors.teal),
              _categoryChip('📦 Groceries', Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 28),

        const Text(
          'Recent Active Offers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Mock Product List Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: Column(
            children: [
              _productItem(
                name: 'Bulk Summer T-Shirts (Lot of 100)',
                wholesaler: 'Al-Karam Textiles Ltd.',
                price: 'Rs 15,000',
                originalPrice: 'Rs 25,000',
              ),
              const Divider(color: AppTheme.border, height: 24),
              _productItem(
                name: 'Premium Leather Sports Shoes (50 Pairs)',
                wholesaler: 'Punjab Footwear Hub',
                price: 'Rs 40,000',
                originalPrice: 'Rs 60,000',
              ),
              const Divider(color: AppTheme.border, height: 24),
              _productItem(
                name: 'Natural Rose Perfume Pack (30 Bottles)',
                wholesaler: 'Kamoke Scents Supplier',
                price: 'Rs 12,000',
                originalPrice: 'Rs 18,000',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        const Text(
          'My Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Buyer Actions
        _actionCard(
          icon: Icons.search_rounded,
          title: 'Search Bulk Products',
          subtitle: 'Search wholesalers catalogues and find active listings.',
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        _actionCard(
          icon: Icons.history_edu_outlined,
          title: 'My Negotiations & Quotes',
          subtitle: 'Check history of sent price offers and negotiations.',
          color: Colors.orange,
        ),
      ],
    );
  }

  // Dashboard Stats card widget
  Widget _statItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [AppTheme.cardShadow],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.08),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Category horizontal scroll chip
  Widget _categoryChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Chip(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.border),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  // Action option card
  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textHint),
        ],
      ),
    );
  }

  // Product listing item widget (for Buyer)
  Widget _productItem({
    required String name,
    required String wholesaler,
    required String price,
    required String originalPrice,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Center(
            child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 24),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'By $wholesaler',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            foregroundColor: AppTheme.primary,
            minimumSize: const Size(60, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          child: const Text('Bid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
