import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/admin_bottom_nav.dart';

class WholesaleCatalogScreen extends StatefulWidget {
  const WholesaleCatalogScreen({super.key});

  @override
  State<WholesaleCatalogScreen> createState() => _WholesaleCatalogScreenState();
}

class _WholesaleCatalogScreenState extends State<WholesaleCatalogScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Clothing',
    'Shoes',
    'Perfumes',
    'Electronics',
    'Groceries'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final data = await AuthService.fetchWholesaleProducts();
    setState(() {
      _allProducts = data;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final wholesaler = (product['wholesaler_name'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString();
        
        final matchesSearch = name.contains(_searchQuery.toLowerCase()) || 
                             wholesaler.contains(_searchQuery.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'All' || 
                                category.toLowerCase() == _selectedCategory.toLowerCase();

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _deleteProduct(int productId, String name) async {
    // Show confirmation dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: const Text('Delete Product Listing', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$name" from the wholesale catalog?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expired),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
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

    final result = await AuthService.deleteProduct(productId);
    Get.back(); // close dialog

    if (result['success']) {
      Get.snackbar(
        "Product Deleted",
        "The product listing was removed successfully.",
        backgroundColor: AppTheme.activeLight,
        colorText: AppTheme.active,
        snackPosition: SnackPosition.BOTTOM,
      );
      _fetchProducts();
    } else {
      Get.snackbar(
        "Deletion Failed",
        result['message'] ?? "Could not delete product.",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _toggleProductStatus(int productId, String currentStatus, String name) async {
    final String newStatus = currentStatus == 'flagged' ? 'active' : 'flagged';
    
    // Show loading
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

    final result = await AuthService.updateProductStatus(productId, newStatus);
    Get.back(); // close dialog

    if (result['success']) {
      Get.snackbar(
        "Status Updated",
        "'$name' is now marked as $newStatus.",
        backgroundColor: newStatus == 'active' ? AppTheme.activeLight : AppTheme.expiredLight,
        colorText: newStatus == 'active' ? AppTheme.active : AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
      _fetchProducts();
    } else {
      Get.snackbar(
        "Action Failed",
        result['message'] ?? "Could not update status.",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: -1),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        onPressed: () => Get.toNamed('/wholesaler-product-form')?.then((_) => _fetchProducts()),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Publish on Behalf'),
      ),
      appBar: AppBar(
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'Wholesalers Catalog',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search product or wholesaler...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: const Color(0xFFF1F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.purple.shade700,
                            backgroundColor: const Color(0xFFECEFF1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _applyFilters();
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Product List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Products Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search query or filters.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final int id = product['id'];
    final String name = product['name'] ?? 'Unnamed Product';
    final String category = product['category'] ?? 'General';
    final double price = (product['price'] ?? 0).toDouble();
    final double originalPrice = (product['original_price'] ?? 0).toDouble();
    final int stock = product['quantity'] ?? 0;
    final String wholesaler = product['wholesaler_name'] ?? 'Unknown Wholesaler';
    final String status = product['status'] ?? 'active';

    final isFlagged = status == 'flagged';

    // Map Category to icon
    IconData categoryIcon = Icons.shopping_bag_outlined;
    if (category.toLowerCase() == 'clothing') {
      categoryIcon = Icons.checkroom_rounded;
    } else if (category.toLowerCase() == 'shoes') {
      categoryIcon = Icons.ice_skating_outlined; // approximate sports shoe
    } else if (category.toLowerCase() == 'perfumes') {
      categoryIcon = Icons.opacity_rounded;
    } else if (category.toLowerCase() == 'electronics') {
      categoryIcon = Icons.electrical_services_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [AppTheme.cardShadow],
        border: isFlagged ? Border.all(color: AppTheme.expired.withValues(alpha: 0.5), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isFlagged ? Colors.red.shade50 : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  categoryIcon,
                  color: isFlagged ? AppTheme.expired : Colors.purple.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              
              // Product Main details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Wholesaler: ',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        Text(
                          wholesaler,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFlagged ? AppTheme.expiredLight : AppTheme.activeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isFlagged ? AppTheme.expired : AppTheme.active,
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 24, color: AppTheme.border),

          // Price & Stock & Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price and Stock details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rs ${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rs ${originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock Lot: $stock items  |  Cat: $category',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Row(
                children: [
                  // Flag Button
                  IconButton(
                    icon: Icon(
                      isFlagged ? Icons.outlined_flag_rounded : Icons.flag_rounded,
                      color: isFlagged ? Colors.grey : Colors.amber.shade700,
                      size: 22,
                    ),
                    onPressed: () => _toggleProductStatus(id, status, name),
                    tooltip: isFlagged ? 'Unflag listing' : 'Flag/suspend listing',
                  ),
                  
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expired, size: 22),
                    onPressed: () => _deleteProduct(id, name),
                    tooltip: 'Remove Listing',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
