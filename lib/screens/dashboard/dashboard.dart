import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/cart_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/wholesaler_drawer.dart';
import '../../core/widgets/wholesaler_bottom_nav.dart';
import '../../core/widgets/client_drawer.dart';
import '../../core/widgets/snackbars.dart';
import '../../core/widgets/client_bottom_nav.dart';
import '../../core/widgets/dialogs.dart';

class DashboardScreen extends StatefulWidget {
<<<<<<< HEAD
  const DashboardScreen({super.key});
=======
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Common states
  bool _isLoading = true;

  // Wholesaler stats states
  List<dynamic> _wholesalerProducts = [];
  List<dynamic> _wholesalerBids = [];

  // Buyer marketplace states
  List<dynamic> _allCategories = [];
  List<dynamic> _allWholesalers = [];
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];

  // Buyer filters
  String? _selectedCategory;
  int _selectedWholesalerId = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final box = GetStorage();
    final user = box.read('user') ?? {};
    final String role = box.read('role') ?? 'buyer';
    final isWholesaler = role.toLowerCase() == 'wholesaler';

    try {
      if (isWholesaler) {
        final wholesalerId = user['id'] ?? 0;
        final results = await Future.wait([
          ProductService.fetchWholesalerProducts(wholesalerId),
          ProductService.fetchWholesalerBids(),
        ]);
        setState(() {
          _wholesalerProducts = results[0];
          _wholesalerBids = results[1];
          _isLoading = false;
        });
      } else {
        final results = await Future.wait([
          ProductService.fetchCategories(),
          ProductService.fetchApprovedWholesalers(),
          ProductService.fetchWholesaleProducts(),
        ]);
        setState(() {
          _allCategories = results[0];
          _allWholesalers = results[1];
          _allProducts = results[2].where((p) => p['status'] != 'flagged').toList();
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      print('Dashboard fetch data error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final desc = (product['description'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString();
        final wholesalerId = product['wholesaler_id'] as int?;

        final matchesSearch = _searchQuery.isEmpty || 
            name.contains(_searchQuery.toLowerCase()) ||
            desc.contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == null ||
            category.toLowerCase() == _selectedCategory!.toLowerCase();

        final matchesWholesaler = _selectedWholesalerId == 0 ||
            wholesalerId == _selectedWholesalerId;

        return matchesSearch && matchesCategory && matchesWholesaler;
      }).toList();
    });
  }
>>>>>>> 4f8040a (Create {order-history, wholesaler-negotiation, Admin(admin-setting, admin-verification, buyer-management, order-audit, buyer-activity)}, Update previous files)

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Common states
  bool _isLoading = true;

  // Wholesaler stats states
  List<dynamic> _wholesalerProducts = [];
  List<dynamic> _wholesalerBids = [];

  // Buyer marketplace states
  List<dynamic> _allCategories = [];
  List<dynamic> _allWholesalers = [];
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];

  // Buyer filters
  String? _selectedCategory;
  int _selectedWholesalerId = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final box = GetStorage();
    final user = box.read('user') ?? {};
    final String role = box.read('role') ?? 'buyer';
    final isWholesaler = role.toLowerCase() == 'wholesaler';

    try {
      if (isWholesaler) {
        final wholesalerId = user['id'] ?? 0;
        final results = await Future.wait([
          ProductService.fetchWholesalerProducts(wholesalerId),
          ProductService.fetchWholesalerBids(),
        ]);
        setState(() {
          _wholesalerProducts = results[0];
          _wholesalerBids = results[1];
          _isLoading = false;
        });
      } else {
        final results = await Future.wait([
          ProductService.fetchCategories(),
          ProductService.fetchApprovedWholesalers(),
          ProductService.fetchWholesaleProducts(),
        ]);
        setState(() {
          _allCategories = results[0];
          _allWholesalers = results[1];
          _allProducts = results[2].where((p) => p['status'] != 'flagged').toList();
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      print('Dashboard fetch data error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final desc = (product['description'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString();
        final wholesalerId = product['wholesaler_id'] as int?;

        final matchesSearch = _searchQuery.isEmpty || 
            name.contains(_searchQuery.toLowerCase()) ||
            desc.contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == null ||
            category.toLowerCase() == _selectedCategory!.toLowerCase();

        final matchesWholesaler = _selectedWholesalerId == 0 ||
            wholesalerId == _selectedWholesalerId;

        return matchesSearch && matchesCategory && matchesWholesaler;
      }).toList();
    });
  }

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

    if (!isWholesaler) {
      Get.put(CartController());
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: isWholesaler ? const WholesalerDrawer() : const ClientDrawer(),
      bottomNavigationBar: isWholesaler
          ? const WholesalerBottomNav(activeIndex: 0)
          : const ClientBottomNav(activeIndex: 0),
      appBar: AppBar(
<<<<<<< HEAD
        backgroundColor: AppTheme.primaryDark,
=======
        backgroundColor: AppTheme.primary,
>>>>>>> 4f8040a (Create {order-history, wholesaler-negotiation, Admin(admin-setting, admin-verification, buyer-management, order-audit, buyer-activity)}, Update previous files)
        foregroundColor: Colors.white,
        title: Text(
          isWholesaler ? 'Wholesaler Portal' : 'Buyer Marketplace',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: isWholesaler
            ? null
            : [
                Obx(() {
                  final cartController = Get.find<CartController>();
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: () => Get.toNamed('/cart'),
                      ),
                      if (cartController.totalCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartController.totalCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(width: 8),
              ],
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
<<<<<<< HEAD
                    colors: [AppTheme.primaryDark, Color.fromARGB(255, 0, 121, 107),],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
=======
                    colors: [AppTheme.primary, Color(0xFF009688)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
>>>>>>> 4f8040a (Create {order-history, wholesaler-negotiation, Admin(admin-setting, admin-verification, buyer-management, order-audit, buyer-activity)}, Update previous files)
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
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (isWholesaler)
                _buildWholesalerDashboard(context, user)
              else
                _buildBuyerDashboard(context),
            ],
          ),
        ),
      ),
    );
  }

  // Wholesaler / Seller UI view
  Widget _buildWholesalerDashboard(BuildContext context, Map<String, dynamic> user) {
    final String totalListings = _wholesalerProducts.length.toString();
    final String pendingOffers = _wholesalerBids.where((b) => b['status'] == 'pending').length.toString();
    final String activeOrders = _wholesalerBids.where((b) => b['status'] == 'ordered').length.toString();
    final String completedDeals = _wholesalerBids.where((b) => b['status'] == 'completed').length.toString();

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
                value: totalListings,
                color: Colors.teal,
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statItem(
                title: 'Pending Offers',
                value: pendingOffers,
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
                value: activeOrders,
                color: Colors.blue,
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statItem(
                title: 'Completed Deals',
                value: completedDeals,
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

        // Action Cards
        _actionCard(
          icon: Icons.add_photo_alternate_outlined,
          title: 'Add New Product Listing',
          subtitle: 'Upload product details, images, and bulk prices.',
          color: Colors.teal,
          onTap: () => Get.toNamed('/wholesaler-product-form'),
        ),
        const SizedBox(height: 12),
        _actionCard(
          icon: Icons.gavel_rounded,
          title: 'Manage Price Negotiations',
          subtitle: 'Review proposed prices and counter-offers from buyers.',
          color: Colors.orange,
          onTap: () => Get.toNamed('/wholesaler-negotiations'),
        ),
        const SizedBox(height: 12),
        _actionCard(
          icon: Icons.assignment_outlined,
          title: 'Incoming Purchase Orders',
          subtitle: 'View placed orders and manage shipping status.',
          color: Colors.blue,
          onTap: () => Get.toNamed('/orders-history'),
        ),
      ],
    );
  }

  // Buyer / Retailer UI view
  Widget _buildBuyerDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SEARCH BAR ---
        const Text(
          'Search Catalog',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          onChanged: (value) {
            _searchQuery = value;
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'Search products by name or details...',
            hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyFilters();
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),

        // --- WHOLESALER FILTER ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filter by Wholesaler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedWholesalerId,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  items: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text('All Wholesalers'),
                    ),
                    ..._allWholesalers.map((w) {
                      return DropdownMenuItem<int>(
                        value: w['id'],
                        child: Text(w['name'] ?? 'Wholesaler'),
                      );
<<<<<<< HEAD
                    }),
=======
                    }).toList(),
>>>>>>> 4f8040a (Create {order-history, wholesaler-negotiation, Admin(admin-setting, admin-verification, buyer-management, order-audit, buyer-activity)}, Update previous files)
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedWholesalerId = val ?? 0;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- CATEGORIES BAR ---
        const Text(
          'Browse Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _categoryChip('All', _selectedCategory == null, () {
                setState(() {
                  _selectedCategory = null;
                  _applyFilters();
                });
              }),
              ..._allCategories.map((cat) {
                final catName = cat['name'] ?? '';
                final isSelected = _selectedCategory?.toLowerCase() == catName.toLowerCase();
                return _categoryChip(catName, isSelected, () {
                  setState(() {
                    _selectedCategory = catName;
                    _applyFilters();
                  });
                });
<<<<<<< HEAD
              }),
=======
              }).toList(),
>>>>>>> 4f8040a (Create {order-history, wholesaler-negotiation, Admin(admin-setting, admin-verification, buyer-management, order-audit, buyer-activity)}, Update previous files)
            ],
          ),
        ),
        const SizedBox(height: 28),

        // --- PRODUCT GRID ---
        const Text(
          'Wholesale Product Catalog',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        _filteredProducts.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: const Center(
                  child: Text(
                    'No products match your selected filters.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  double childAspectRatio = 0.68;

                  if (width > 1200) {
                    crossAxisCount = 5;
                    childAspectRatio = 0.82;
                  } else if (width > 800) {
                    crossAxisCount = 4;
                    childAspectRatio = 0.76;
                  } else if (width > 600) {
                    crossAxisCount = 3;
                    childAspectRatio = 0.72;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final p = _filteredProducts[index] as Map<String, dynamic>;
                      final cartController = Get.find<CartController>();
                      return _productGridItem(context, p, cartController);
                    },
                  );
                },
              ),
        const SizedBox(height: 28),

        // --- MY ACTIONS ---
        const Text(
          'My Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _actionCard(
          icon: Icons.history_edu_outlined,
          title: 'My Negotiations & Quotes',
          subtitle: 'Check history of sent price offers and negotiations.',
          color: Colors.orange,
          onTap: () => Get.toNamed('/buyer-negotiations'),
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
  Widget _categoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
<<<<<<< HEAD
                    color: AppTheme.primary.withValues(alpha: 0.2),
=======
                    color: AppTheme.primary.withOpacity(0.2),
>>>>>>> 4f8040a (Create {order-history, wholesaler-negotiation, Admin(admin-setting, admin-verification, buyer-management, order-audit, buyer-activity)}, Update previous files)
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  // Product grid item card (for Buyer Marketplace)
  Widget _productGridItem(BuildContext context, Map<String, dynamic> product, CartController cartController) {
    final name = product['name'] ?? '';
    final wholesaler = product['wholesaler_name'] ?? 'Wholesaler';
    final priceStr = 'Rs ${(product['price'] ?? 0)}';
    final originalPriceStr = 'Rs ${(product['original_price'] ?? 0)}';
    final qty = product['quantity'] ?? 0;
    final String? productImage = product['product_image'];
    final bool hasImage = productImage != null && productImage.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
<<<<<<< HEAD
            color: Colors.black.withValues(alpha: 0.01),
=======
            color: Colors.black.withOpacity(0.01),
>>>>>>> 4f8040a (Create {order-history, wholesaler-negotiation, Admin(admin-setting, admin-verification, buyer-management, order-audit, buyer-activity)}, Update previous files)
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Header
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusMd),
              topRight: Radius.circular(AppTheme.radiusMd),
            ),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: hasImage
                  ? Image.memory(
                      base64Decode(productImage),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF1F4F6),
                        child: const Center(child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 30)),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF1F4F6),
                      child: const Center(child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 30)),
                    ),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name and Wholesaler
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "By $wholesaler",
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "Stock: $qty units",
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Pricing
                  Row(
                    children: [
                      Text(
                        priceStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        originalPriceStr,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  
                  // Action Buttons (Add & Bid)
                  Row(
                    children: [
                      // Add Button
                      Expanded(
                        child: SizedBox(
                          height: 26,
                          child: ElevatedButton(
                            onPressed: qty <= 0 ? null : () {
                              cartController.addToCart(product);
                              AppSnackbars.success(
                                title: "Added to Cart",
                                message: "$name has been added to your cart.",
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: qty <= 0 ? Colors.grey : AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              elevation: 0,
                            ),
                            child: Text(qty <= 0 ? 'Sold Out' : 'Add', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Bid Button
                      Expanded(
                        child: SizedBox(
                          height: 26,
                          child: ElevatedButton(
                            onPressed: qty <= 0 ? null : () {
                              showBidDialog(
                                context: context,
                                product: product,
                                onSuccess: () {},
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: qty <= 0 ? Colors.grey.shade200 : AppTheme.primaryLight,
                              foregroundColor: qty <= 0 ? Colors.grey : AppTheme.primary,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Bid', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Product listing item widget (for Buyer)
  Widget _productItem(BuildContext context, Map<String, dynamic> product, CartController cartController) {
    final name = product['name'] ?? '';
    final wholesaler = product['wholesaler_name'] ?? 'Wholesaler';
    final priceStr = 'Rs ${(product['price'] ?? 0)}';
    final originalPriceStr = 'Rs ${(product['original_price'] ?? 0)}';
    final qty = product['quantity'] ?? 0;
    final category = product['category'] ?? '';
    final String? productImage = product['product_image'];
    final bool hasImage = productImage != null && productImage.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: SizedBox(
            width: 56,
            height: 56,
            child: hasImage
                ? Image.memory(
                    base64Decode(productImage),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFECEFF1),
                      child: const Center(child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 24)),
                    ),
                  )
                : Container(
                    color: const Color(0xFFECEFF1),
                    child: const Center(child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 24)),
                  ),
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
                'By $wholesaler • $category',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Stock: $qty units available',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    priceStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    originalPriceStr,
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
        Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                cartController.addToCart(product);
                AppSnackbars.success(
                  title: "Added to Cart",
                  message: "$name has been added to your shopping cart.",
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 14),
              label: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () {
                showBidDialog(
                  context: context,
                  product: product,
                  onSuccess: () {},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(80, 30),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: const Text('Bid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}