import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../admin/services/admin_service.dart';
import '../../buyer/services/buyer_service.dart';
import '../../../core/theme/theme.dart';
import './widgets/admin_drawer.dart';
import './widgets/admin_bottom_nav.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/snackbars.dart';

class WholesaleCatalogScreen extends StatefulWidget {
  const WholesaleCatalogScreen({super.key});

  @override
  State<WholesaleCatalogScreen> createState() =>
      _WholesaleCatalogScreenState();
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
    'Groceries',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // ============================================================
  // SAFE NUMBER CONVERSION
  // Handles:
  // 600
  // 600.00
  // "600"
  // "600.00"
  // null
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // FETCH PRODUCTS
  // ============================================================

  Future<void> _fetchProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await BuyerService.fetchWholesaleProducts();

      if (!mounted) return;

      _allProducts = data;

      _applyFilters();
    } catch (e) {
      debugPrint('Fetch wholesale products error: $e');

      if (!mounted) return;

      setState(() {
        _allProducts = [];
        _filteredProducts = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // APPLY FILTERS
  // ============================================================

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _allProducts.where((product) {
      final name =
          (product['name'] ?? '').toString().toLowerCase();

      final wholesaler =
          (product['wholesaler_name'] ?? '')
              .toString()
              .toLowerCase();

      final category =
          (product['category'] ?? '').toString();

      final matchesSearch =
          name.contains(query) ||
          wholesaler.contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
          category.toLowerCase() ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredProducts = filtered;
    });
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> _deleteProduct(
    int productId,
    String name,
  ) async {
    final confirm = await showConfirmDialog(
      title: 'Delete Product Listing',
      content:
          'Are you sure you want to delete "$name" from the wholesale catalog?',
    );

    if (!confirm) return;

    showLoadingDialog();

    try {
      final result =
          await AdminService.deleteProduct(productId);

      // Close loading dialog safely
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (result['success'] == true) {
        AppSnackbars.success(
          title: 'Product Deleted',
          message:
              'The product listing was removed successfully.',
        );

        await _fetchProducts();
      } else {
        AppSnackbars.error(
          title: 'Deletion Failed',
          message:
              result['message'] ??
                  'Could not delete product.',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      debugPrint('Delete product error: $e');

      AppSnackbars.error(
        title: 'Deletion Failed',
        message: 'Something went wrong while deleting the product.',
      );
    }
  }

  // ============================================================
  // TOGGLE PRODUCT STATUS
  // ============================================================

  Future<void> _toggleProductStatus(
    int productId,
    String currentStatus,
    String name,
  ) async {
    final String newStatus =
        currentStatus.toLowerCase() == 'flagged'
            ? 'active'
            : 'flagged';

    showLoadingDialog();

    try {
      final result =
          await AdminService.updateProductStatus(
        productId,
        newStatus,
      );

      // Close loading dialog safely
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (result['success'] == true) {
        if (newStatus == 'active') {
          AppSnackbars.success(
            title: 'Status Updated',
            message:
                "'$name' is now marked as active.",
          );
        } else {
          AppSnackbars.error(
            title: 'Status Updated',
            message:
                "'$name' is now marked as flagged.",
          );
        }

        await _fetchProducts();
      } else {
        AppSnackbars.error(
          title: 'Action Failed',
          message:
              result['message'] ??
                  'Could not update status.',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      debugPrint('Update product status error: $e');

      AppSnackbars.error(
        title: 'Action Failed',
        message:
            'Something went wrong while updating the product.',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      drawer: const AdminDrawer(),

      bottomNavigationBar: const AdminBottomNav(
        activeIndex: -1,
      ),

      // ==========================================================
      // FLOATING ACTION BUTTON
      // ==========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryDark,
        foregroundColor: Colors.white,

        onPressed: () {
          Get.toNamed(
            '/wholesaler-product-form',
          )?.then((_) {
            _fetchProducts();
          });
        },

        icon: const Icon(
          Icons.add_circle_outline_rounded,
        ),

        label: const Text(
          'Publish on Behalf',
        ),
      ),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,

        title: const Text(
          'Wholesalers Catalog',
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed: _fetchProducts,
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: Column(
          children: [

            // ======================================================
            // SEARCH & FILTER HEADER
            // ======================================================

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,

              child: Column(
                children: [

                  // ==================================================
                  // SEARCH BAR
                  // ==================================================

                  TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },

                    decoration: InputDecoration(
                      hintText:
                          'Search product or wholesaler...',

                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.textThird,
                      ),

                      filled: true,

                      fillColor:
                          AppTheme.textLight,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppTheme.radiusMd,
                        ),

                        borderSide:
                            BorderSide.none,
                      ),

                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // CATEGORY CHIPS
                  // ==================================================

                  SizedBox(
                    height: 38,

                    child: ListView.builder(
                      scrollDirection:
                          Axis.horizontal,

                      itemCount:
                          _categories.length,

                      itemBuilder:
                          (context, index) {
                        final cat =
                            _categories[index];

                        final isSelected =
                            _selectedCategory ==
                                cat;

                        return Container(
                          margin:
                              const EdgeInsets.only(
                            right: 8,
                          ),

                          child: ChoiceChip(
                            label: Text(
                              cat,

                              style: TextStyle(
                                fontSize: 12,

                                fontWeight:
                                    FontWeight.bold,

                                color: isSelected
                                    ? Colors.white
                                    : AppTheme
                                        .secondaryDark,
                              ),
                            ),

                            selected:
                                isSelected,

                            selectedColor:
                                AppTheme
                                    .secondaryDark,

                            backgroundColor:
                                const Color(
                              0xFFECEFF1,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),

                            onSelected:
                                (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory =
                                      cat;
                                });

                                _applyFilters();
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

            // ======================================================
            // PRODUCT LIST
            // ======================================================

            Expanded(
              child: _isLoading

                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            AppTheme.secondary,
                      ),
                    )

                  : _filteredProducts.isEmpty
                      ? _buildEmptyState()

                      : ListView.separated(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),

                          itemCount:
                              _filteredProducts
                                  .length,

                          separatorBuilder:
                              (context, index) =>
                                  const SizedBox(
                            height: 12,
                          ),

                          itemBuilder:
                              (context, index) {
                            final product =
                                _filteredProducts[
                                    index];

                            return _buildProductCard(
                              product,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          const Text(
            'No Products Found',

            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Try adjusting your search query or filters.',

            style: TextStyle(
              fontSize: 13,
              color:
                  AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
    dynamic product,
  ) {
    // ==========================================================
    // SAFE ID
    // ==========================================================

    final int id = _toInt(
      product['id'],
    );

    // ==========================================================
    // SAFE STRING VALUES
    // ==========================================================

    final String name =
        (product['name'] ??
                'Unnamed Product')
            .toString();

    final String category =
        (product['category'] ??
                'General')
            .toString();

    final String wholesaler =
        (product['wholesaler_name'] ??
                'Unknown Wholesaler')
            .toString();

    final String status =
        (product['status'] ??
                'active')
            .toString();

    // ==========================================================
    // IMPORTANT FIX:
    // API can return price as String:
    //
    // "600.00"
    //
    // So DO NOT use:
    // (product['price'] ?? 0).toDouble()
    // ==========================================================

    final double price = _toDouble(
      product['price'],
    );

    final double originalPrice =
        _toDouble(
      product['original_price'],
    );

    // ==========================================================
    // SAFE STOCK
    // ==========================================================

    final int stock = _toInt(
      product['quantity'],
    );

    final bool isFlagged =
        status.toLowerCase() ==
            'flagged';

    // ==========================================================
    // MAP CATEGORY TO ICON
    // ==========================================================

    IconData categoryIcon =
        Icons.shopping_bag_outlined;

    if (category.toLowerCase() ==
        'clothing') {
      categoryIcon =
          Icons.checkroom_rounded;
    } else if (category.toLowerCase() ==
        'shoes') {
      categoryIcon =
          Icons.ice_skating_outlined;
    } else if (category.toLowerCase() ==
        'perfumes') {
      categoryIcon =
          Icons.opacity_rounded;
    } else if (category.toLowerCase() ==
        'electronics') {
      categoryIcon =
          Icons.electrical_services_rounded;
    }

    // ==========================================================
    // PRODUCT IMAGE
    // ==========================================================

    final String? productImage =
        product['product_image']
            ?.toString();

    final bool hasImage =
        productImage != null &&
        productImage.isNotEmpty;

    // ==========================================================
    // PRODUCT CARD
    // ==========================================================

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          AppTheme.radiusMd,
        ),

        boxShadow: [
          AppTheme.cardShadow,
        ],

        border: isFlagged
            ? Border.all(
                color: AppTheme.expired
                    .withValues(
                  alpha: 0.5,
                ),
                width: 1.5,
              )
            : null,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ======================================================
          // PRODUCT HEADER
          // ======================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ==================================================
              // PRODUCT IMAGE / CATEGORY ICON
              // ==================================================

              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  color: isFlagged
                      ? Colors.red.shade50
                      : AppTheme.textLight,

                  borderRadius:
                      BorderRadius.circular(
                    AppTheme.radiusSm,
                  ),
                ),

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    AppTheme.radiusSm,
                  ),

                  child: hasImage
                      ? Image.memory(
                          base64Decode(
                            productImage!,
                          ),

                          fit:
                              BoxFit.cover,

                          errorBuilder:
                              (
                            _,
                            __,
                            ___,
                          ) {
                            return Icon(
                              categoryIcon,

                              color: isFlagged
                                  ? AppTheme
                                      .expired
                                  : AppTheme
                                      .secondary,

                              size: 24,
                            );
                          },
                        )

                      : Icon(
                          categoryIcon,

                          color: isFlagged
                              ? AppTheme.expired
                              : AppTheme.secondary,

                          size: 24,
                        ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // ==================================================
              // PRODUCT MAIN DETAILS
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    Text(
                      name,

                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color: AppTheme
                            .textPrimary,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Row(
                      children: [

                        Text(
                          'Wholesaler: ',

                          style: TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade500,
                          ),
                        ),

                        Expanded(
                          child: Text(
                            wholesaler,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color: AppTheme
                                  .textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // ==================================================
              // STATUS BADGE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),

                decoration:
                    BoxDecoration(
                  color: isFlagged
                      ? AppTheme
                          .expiredLight
                      : AppTheme
                          .activeLight,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Text(
                  status.toUpperCase(),

                  style: TextStyle(
                    fontSize: 9,

                    fontWeight:
                        FontWeight.bold,

                    color: isFlagged
                        ? AppTheme.expired
                        : AppTheme.active,
                  ),
                ),
              ),
            ],
          ),

          const Divider(
            height: 24,
            color: AppTheme.border,
          ),

          // ======================================================
          // PRICE & STOCK & ACTION BUTTONS
          // ======================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [

              // ==================================================
              // PRICE & STOCK
              // ==================================================

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Row(
                    children: [

                      Text(
                        'Rs ${price.toStringAsFixed(0)}',

                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: AppTheme
                              .primary,
                        ),
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Text(
                        'Rs ${originalPrice.toStringAsFixed(0)}',

                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme
                                  .textHint,
                          decoration:
                              TextDecoration
                                  .lineThrough,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Stock Lot: $stock items  |  Cat: $category',

                    style:
                        const TextStyle(
                      fontSize: 11,
                      color: AppTheme
                          .textSecondary,
                    ),
                  ),
                ],
              ),

              // ==================================================
              // ACTION BUTTONS
              // ==================================================

              Row(
                children: [

                  // ==============================================
                  // FLAG BUTTON
                  // ==============================================

                  IconButton(
                    icon: Icon(
                      isFlagged
                          ? Icons
                              .outlined_flag_rounded
                          : Icons.flag_rounded,

                      color: isFlagged
                          ? Colors.grey
                          : Colors.amber
                              .shade700,

                      size: 22,
                    ),

                    onPressed: () =>
                        _toggleProductStatus(
                      id,
                      status,
                      name,
                    ),

                    tooltip: isFlagged
                        ? 'Unflag listing'
                        : 'Flag/suspend listing',
                  ),

                  // ==============================================
                  // EDIT BUTTON
                  // ==============================================

                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color:
                          Colors.blue.shade700,
                      size: 22,
                    ),

                    onPressed: () {
                      Get.toNamed(
                        '/wholesaler-product-form',
                        arguments: product,
                      )?.then((_) {
                        _fetchProducts();
                      });
                    },

                    tooltip:
                        'Edit Listing',
                  ),

                  // ==============================================
                  // DELETE BUTTON
                  // ==============================================

                  IconButton(
                    icon: const Icon(
                      Icons
                          .delete_outline_rounded,
                      color:
                          AppTheme.expired,
                      size: 22,
                    ),

                    onPressed: () =>
                        _deleteProduct(
                      id,
                      name,
                    ),

                    tooltip:
                        'Remove Listing',
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