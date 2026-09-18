import 'package:flutter/material.dart';
import 'dart:convert';

import '../../admin/services/admin_service.dart';
import '../../buyer/services/buyer_service.dart';
import '../../../core/theme/theme.dart';
import './widgets/admin_drawer.dart';
import './widgets/admin_bottom_nav.dart';

class OrdersAuditScreen extends StatefulWidget {
  const OrdersAuditScreen({super.key});

  @override
  State<OrdersAuditScreen> createState() => _OrdersAuditScreenState();
}

class _OrdersAuditScreenState extends State<OrdersAuditScreen> {
  bool _isLoading = true;

  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  List<dynamic> _wholesalers = [];

  String _searchQuery = '';
  String _selectedStatus = 'All';
  int _selectedWholesalerId = 0;

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SAFE NUMBER CONVERSION
  // Handles both:
  // 1020.00
  // "1020.00"
  // 1020
  // null
  // ------------------------------------------------------------

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ------------------------------------------------------------
  // PARSE ORDER ITEMS SAFELY
  // ------------------------------------------------------------

  List<dynamic> _parseItems(dynamic items) {
    if (items == null) {
      return [];
    }

    if (items is List) {
      return items;
    }

    if (items is String) {
      try {
        final decoded = json.decode(items);

        if (decoded is List) {
          return decoded;
        }

        return [];
      } catch (_) {
        return [];
      }
    }

    return [];
  }

  // ------------------------------------------------------------
  // FETCH ORDERS
  // ------------------------------------------------------------

  Future<void> _fetchOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        AdminService.fetchAdminOrders(),
        BuyerService.fetchApprovedWholesalers(),
      ]);

      if (!mounted) return;

      _allOrders = results[0];
      _wholesalers = results[1];

      _applyFilters();
    } catch (e) {
      debugPrint('Fetch admin orders error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // APPLY FILTERS
  // ------------------------------------------------------------

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _allOrders.where((order) {
      final idStr = '#${order['id'] ?? ''}';

      final buyerName =
          (order['buyer_name'] ?? '').toString().toLowerCase();

      final status =
          (order['status'] ?? 'pending').toString().toLowerCase();

      final itemsList = _parseItems(order['items']);

      // --------------------------------------------------------
      // SEARCH
      // Order ID / Buyer Name / Product Name
      // --------------------------------------------------------

      final matchesSearch =
          query.isEmpty ||
          idStr.toLowerCase().contains(query) ||
          buyerName.contains(query) ||
          itemsList.any((item) {
            if (item is! Map) return false;

            final productName =
                (item['name'] ?? '').toString().toLowerCase();

            return productName.contains(query);
          });

      // --------------------------------------------------------
      // STATUS FILTER
      // --------------------------------------------------------

      final matchesStatus =
          _selectedStatus == 'All' ||
          status == _selectedStatus.toLowerCase();

      // --------------------------------------------------------
      // WHOLESALER FILTER
      // --------------------------------------------------------

      final matchesWholesaler =
          _selectedWholesalerId == 0 ||
          itemsList.any((item) {
            if (item is! Map) return false;

            final itemWholesalerId =
                _toInt(item['wholesaler_id']);

            return itemWholesalerId == _selectedWholesalerId;
          });

      return matchesSearch &&
          matchesStatus &&
          matchesWholesaler;
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredOrders = filtered;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      drawer: const AdminDrawer(),

      bottomNavigationBar: const AdminBottomNav(
        activeIndex: -1,
      ),

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Marketplace Orders log'),

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchOrders,
          ),
        ],
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: SafeArea(
        child: Column(
          children: [

            // ====================================================
            // FILTERS BAR
            // ====================================================

            Padding(
              padding: const EdgeInsets.all(16.0),

              child: Column(
                children: [

                  // ------------------------------------------------
                  // SEARCH FIELD
                  // ------------------------------------------------

                  TextField(
                    controller: _searchController,

                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },

                    decoration: InputDecoration(
                      hintText:
                          'Search by Order #, Buyer, or Product...',

                      hintStyle: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 13,
                      ),

                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),

                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color:
                                    AppTheme.secondaryLight,
                                size: 18,
                              ),

                              onPressed: () {
                                _searchController.clear();

                                _searchQuery = '';

                                _applyFilters();
                              },
                            )
                          : null,

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppTheme.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppTheme.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppTheme.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                      ),

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // DROPDOWN FILTERS
                  // =================================================

                  Row(
                    children: [

                      // ---------------------------------------------
                      // WHOLESALER FILTER
                      // ---------------------------------------------

                      Expanded(
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius:
                                BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),

                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),

                          child:
                              DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedWholesalerId,

                              isExpanded: true,

                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.primary,
                              ),

                              style: const TextStyle(
                                fontSize: 13,
                                color:
                                    AppTheme.textPrimary,
                                fontWeight:
                                    FontWeight.w600,
                              ),

                              items: [
                                const DropdownMenuItem<int>(
                                  value: 0,
                                  child: Text(
                                    'All Sellers',
                                  ),
                                ),

                                ..._wholesalers.map((w) {
                                  final wholesalerId =
                                      _toInt(w['id']);

                                  final wholesalerName =
                                      (w['name'] ??
                                              'Seller')
                                          .toString();

                                  return DropdownMenuItem<int>(
                                    value: wholesalerId,

                                    child: Text(
                                      wholesalerName,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],

                              onChanged: (val) {
                                setState(() {
                                  _selectedWholesalerId =
                                      val ?? 0;
                                });

                                _applyFilters();
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ---------------------------------------------
                      // STATUS FILTER
                      // ---------------------------------------------

                      Expanded(
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius:
                                BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),

                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),

                          child:
                              DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,

                              isExpanded: true,

                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.primary,
                              ),

                              style: const TextStyle(
                                fontSize: 13,
                                color:
                                    AppTheme.textPrimary,
                                fontWeight:
                                    FontWeight.w600,
                              ),

                              items: const [
                                DropdownMenuItem(
                                  value: 'All',
                                  child: Text(
                                    'All Statuses',
                                  ),
                                ),

                                DropdownMenuItem(
                                  value: 'Pending',
                                  child: Text(
                                    'Pending',
                                  ),
                                ),

                                DropdownMenuItem(
                                  value: 'Shipped',
                                  child: Text(
                                    'Shipped',
                                  ),
                                ),

                                DropdownMenuItem(
                                  value: 'Delivered',
                                  child: Text(
                                    'Delivered',
                                  ),
                                ),
                              ],

                              onChanged: (val) {
                                setState(() {
                                  _selectedStatus =
                                      val ?? 'All';
                                });

                                _applyFilters();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ====================================================
            // MAIN LIST / BODY
            // ====================================================

            Expanded(
              child: _isLoading

                  // ------------------------------------------------
                  // LOADING
                  // ------------------------------------------------

                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    )

                  // ------------------------------------------------
                  // EMPTY
                  // ------------------------------------------------

                  : _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'No Matching Orders Found',

                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      AppTheme.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Try refining your search keyword or active status flags.',

                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )

                      // ------------------------------------------------
                      // ORDERS LIST
                      // ------------------------------------------------

                      : ListView.separated(
                          padding:
                              const EdgeInsets.all(16),

                          itemCount:
                              _filteredOrders.length,

                          separatorBuilder:
                              (context, index) =>
                                  const SizedBox(
                            height: 14,
                          ),

                          itemBuilder:
                              (context, index) {
                            final order =
                                _filteredOrders[index];

                            // ========================================
                            // ORDER BASIC DATA
                            // ========================================

                            final id =
                                order['id'] ?? '';

                            final buyerName =
                                (order['buyer_name'] ??
                                        'Buyer')
                                    .toString();

                            final address =
                                (order['shipping_address'] ??
                                        'N/A')
                                    .toString();

                            final phone =
                                (order['phone'] ?? 'N/A')
                                    .toString();

                            // ========================================
                            // FIX:
                            // total_amount may be String
                            // ========================================

                            final totalAmount =
                                _toDouble(
                              order['total_amount'],
                            );

                            final paymentMethod =
                                (order['payment_method'] ??
                                        'cash')
                                    .toString()
                                    .toUpperCase();

                            final date =
                                order['created_at'] != null
                                    ? order['created_at']
                                        .toString()
                                        .split('T')[0]
                                    : '';

                            // ========================================
                            // ORDER ITEMS
                            // ========================================

                            final itemsList =
                                _parseItems(
                              order['items'],
                            );

                            // ========================================
                            // ORDER CARD
                            // ========================================

                            return Card(
                              color: Colors.white,

                              elevation: 0,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),

                                side: BorderSide(
                                  color:
                                      Colors.grey.shade200,
                                ),
                              ),

                              margin: EdgeInsets.zero,

                              child: Padding(
                                padding:
                                    const EdgeInsets.all(
                                  16,
                                ),

                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    // ==================================
                                    // ORDER HEADER
                                    // ==================================

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,

                                      children: [
                                        Text(
                                          'Order #$id',

                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 15,
                                            color: AppTheme
                                                .secondaryDark,
                                          ),
                                        ),

                                        if (date.isNotEmpty)
                                          Text(
                                            date,

                                            style:
                                                const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme
                                                  .textHint,
                                            ),
                                          ),
                                      ],
                                    ),

                                    const Divider(
                                      height: 20,
                                      color:
                                          AppTheme.border,
                                    ),

                                    // ==================================
                                    // BUYER
                                    // ==================================

                                    Row(
                                      children: [
                                        const Text(
                                          'Buyer: ',

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 13,
                                            color: AppTheme
                                                .textPrimary,
                                          ),
                                        ),

                                        Expanded(
                                          child: Text(
                                            buyerName,

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme
                                                  .textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    // ==================================
                                    // ADDRESS
                                    // ==================================

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [
                                        const Text(
                                          'Address: ',

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 13,
                                            color: AppTheme
                                                .textPrimary,
                                          ),
                                        ),

                                        Expanded(
                                          child: Text(
                                            address,

                                            style:
                                                const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme
                                                  .textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    // ==================================
                                    // CONTACT
                                    // ==================================

                                    Row(
                                      children: [
                                        const Text(
                                          'Contact: ',

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 13,
                                            color: AppTheme
                                                .textPrimary,
                                          ),
                                        ),

                                        Expanded(
                                          child: Text(
                                            phone,

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme
                                                  .textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    // ==================================
                                    // ORDER ITEMS HEADER
                                    // ==================================

                                    const Text(
                                      'Order Items:',

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme
                                            .textPrimary,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    // ==================================
                                    // ITEMS CONTAINER
                                    // ==================================

                                    Container(
                                      decoration:
                                          BoxDecoration(
                                        color: AppTheme
                                            .background,

                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          AppTheme.radiusSm,
                                        ),
                                      ),

                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),

                                      child:
                                          itemsList.isEmpty
                                              ? const Text(
                                                  'No items found',
                                                  style:
                                                      TextStyle(
                                                    fontSize:
                                                        12,
                                                    color: AppTheme
                                                        .textSecondary,
                                                  ),
                                                )
                                              : ListView
                                                  .builder(
                                                  shrinkWrap:
                                                      true,

                                                  physics:
                                                      const NeverScrollableScrollPhysics(),

                                                  itemCount:
                                                      itemsList
                                                          .length,

                                                  itemBuilder:
                                                      (context,
                                                          itemIdx) {
                                                    final item =
                                                        itemsList[
                                                            itemIdx];

                                                    if (item
                                                        is! Map) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }

                                                    final name =
                                                        (item['name'] ??
                                                                'Product')
                                                            .toString();

                                                    final qty =
                                                        _toInt(
                                                      item[
                                                          'quantity'],
                                                    );

                                                    final safeQty =
                                                        qty > 0
                                                            ? qty
                                                            : 1;

                                                    final price =
                                                        _toDouble(
                                                      item[
                                                          'price'],
                                                    );

                                                    final wholesalerName =
                                                        (item['wholesaler_name'] ??
                                                                'Wholesaler')
                                                            .toString();

                                                    // ==================================
                                                    // ITEM ROW
                                                    // ==================================

                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        vertical:
                                                            4.0,
                                                      ),

                                                      child:
                                                          Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.spaceBetween,

                                                        children: [

                                                          Expanded(
                                                            child:
                                                                Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment.start,

                                                              children: [
                                                                Text(
                                                                  '$name (x$safeQty)',

                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        AppTheme.textPrimary,
                                                                    fontWeight:
                                                                        FontWeight.bold,
                                                                  ),

                                                                  maxLines:
                                                                      1,

                                                                  overflow:
                                                                      TextOverflow.ellipsis,
                                                                ),

                                                                const SizedBox(
                                                                  height:
                                                                      2,
                                                                ),

                                                                Text(
                                                                  'Seller: $wholesalerName',

                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color:
                                                                        AppTheme.textSecondary,
                                                                  ),

                                                                  maxLines:
                                                                      1,

                                                                  overflow:
                                                                      TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                            width:
                                                                10,
                                                          ),

                                                          Text(
                                                            'Rs ${(price * safeQty).toStringAsFixed(0)}',

                                                            style:
                                                                const TextStyle(
                                                              fontSize:
                                                                  12,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              color:
                                                                  AppTheme.textSecondary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    // ==================================
                                    // PAYMENT + TOTAL
                                    // ==================================

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,

                                      children: [

                                        // ------------------------------
                                        // PAYMENT METHOD
                                        // ------------------------------

                                        Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .payment_rounded,
                                              size: 16,
                                              color: AppTheme
                                                  .textSecondary,
                                            ),

                                            const SizedBox(
                                              width: 6,
                                            ),

                                            Text(
                                              paymentMethod,

                                              style:
                                                  const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                color: AppTheme
                                                    .textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ------------------------------
                                        // TOTAL
                                        // ------------------------------

                                        Text(
                                          'Total: Rs ${totalAmount.toStringAsFixed(0)}',

                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 16,
                                            color: AppTheme
                                                .primary,
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
          ],
        ),
      ),
    );
  }
}