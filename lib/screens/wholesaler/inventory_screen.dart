import 'dart:convert';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/wholesaler_drawer.dart';
import '../../core/widgets/wholesaler_bottom_nav.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/snackbars.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/snackbars.dart';

class WholesalerInventoryScreen extends StatefulWidget {
  const WholesalerInventoryScreen({Key? key}) : super(key: key);

  @override
  State<WholesalerInventoryScreen> createState() => _WholesalerInventoryScreenState();
}

class _WholesalerInventoryScreenState extends State<WholesalerInventoryScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  int _wholesalerId = 0;

  @override
  void initState() {
    super.initState();
    _getWholesalerId();
  }

  void _getWholesalerId() {
    final box = GetStorage();
    final user = box.read('user') ?? {};
    _wholesalerId = user['id'] ?? 0;
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_wholesalerId == 0) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await ProductService.fetchWholesalerProducts(_wholesalerId);
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching wholesaler products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int productId, String name) async {
    final confirm = await showConfirmDialog(
      title: 'Delete Product',
      content: 'Are you sure you want to permanently delete "$name" from your catalog?',
      confirmColor: AppTheme.expired,
    );

    if (!confirm) return;

    showLoadingDialog(color: AppTheme.primary);
    final confirm = await showConfirmDialog(
      title: 'Delete Product',
      content: 'Are you sure you want to permanently delete "$name" from your catalog?',
      confirmColor: AppTheme.expired,
    );

    if (!confirm) return;

    showLoadingDialog(color: AppTheme.primary);

    final result = await ProductService.deleteWholesalerProduct(productId);
    Get.back(); // close loading
    final result = await ProductService.deleteWholesalerProduct(productId);
    Get.back(); // close loading

    if (result['success']) {
      AppSnackbars.success(
        title: "Product Deleted",
        message: "Product has been removed from your catalog.",
      );
      _fetchProducts();
    } else {
      AppSnackbars.error(
        title: "Delete Failed",
        message: result['message'] ?? "Unable to delete product.",
      );
    }
    if (result['success']) {
      AppSnackbars.success(
        title: "Product Deleted",
        message: "Product has been removed from your catalog.",
      );
      _fetchProducts();
    } else {
      AppSnackbars.error(
        title: "Delete Failed",
        message: result['message'] ?? "Unable to delete product.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      backgroundColor: AppTheme.background,
      drawer: const WholesalerDrawer(),
      bottomNavigationBar: const WholesalerBottomNav(activeIndex: 1),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('My Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProducts,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => Get.toNamed('/wholesaler-product-form')?.then((_) => _fetchProducts()),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Publish Product'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No Products Published',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Publish products to showcase them to buyers.',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final name = product['name'] ?? 'Unnamed Product';
                      final category = product['category'] ?? 'General';
                      final double price = double.tryParse(product['price'].toString()) ?? 0.0;
                      final double origPrice = double.tryParse(product['original_price'].toString()) ?? price;
                      final int qty = int.tryParse(product['quantity'].toString()) ?? 1;
                      final status = product['status'] ?? 'active';
                      final String? productImage = product['product_image'];
                      final bool hasImage = productImage != null && productImage.isNotEmpty;
                      final String? productImage = product['product_image'];
                      final bool hasImage = productImage != null && productImage.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      child: hasImage
                                          ? Image.memory(
                                              base64Decode(productImage!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.shopping_bag_outlined,
                                                color: AppTheme.primary,
                                                size: 28,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.shopping_bag_outlined,
                                              color: AppTheme.primary,
                                              size: 28,
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
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            category,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                      ),
                                      if (origPrice > price)
                                        Text(
                                          'Rs. ${origPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textHint,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: AppTheme.border),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Quantity badge
                                      Icon(Icons.inventory_rounded, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Stock: $qty units',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 16),
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: status == 'active' ? AppTheme.activeLight : AppTheme.expiredLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'active' ? AppTheme.active : AppTheme.expired,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700, size: 20),
                                        icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700, size: 20),
                                        onPressed: () {
                                          Get.toNamed(
                                            '/wholesaler-product-form',
                                            arguments: product,
                                          )?.then((_) => _fetchProducts());
                                        },
                                        tooltip: 'Edit Details',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expired, size: 20),
                                        onPressed: () => _deleteProduct(product['id'], name),
                                        tooltip: 'Delete Product',
                                      ),
                                    ],
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