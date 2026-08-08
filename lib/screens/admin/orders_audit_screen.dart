import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/admin_bottom_nav.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ProductService.fetchAdminOrders(),
        ProductService.fetchApprovedWholesalers(),
      ]);
      _allOrders = results[0];
      _wholesalers = results[1];
      _applyFilters();
    } catch (e) {
      print('Fetch admin orders error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final idStr = "#${order['id']}";
        final buyerName = (order['buyer_name'] ?? '').toString().toLowerCase();
        final status = (order['status'] ?? 'pending').toString().toLowerCase();

        // Parse items list
        List<dynamic> itemsList = [];
        if (order['items'] != null) {
          if (order['items'] is String) {
            try {
              itemsList = json.decode(order['items']);
            } catch (_) {}
          } else if (order['items'] is List) {
            itemsList = order['items'];
          }
        }

        // Search matches Order ID, Buyer Name, or Product Name
        final matchesSearch = _searchQuery.isEmpty ||
            idStr.contains(_searchQuery) ||
            buyerName.contains(_searchQuery.toLowerCase()) ||
            itemsList.any((item) => (item['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()));

        // Status match
        final matchesStatus = _selectedStatus == 'All' ||
            status == _selectedStatus.toLowerCase();

        // Wholesaler match
        final matchesWholesaler = _selectedWholesalerId == 0 ||
            itemsList.any((item) => item['wholesaler_id'] == _selectedWholesalerId);

        return matchesSearch && matchesStatus && matchesWholesaler;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: -1), // Admin Audit view
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Marketplace Orders log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchOrders,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- FILTERS BAR ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by Order #, Buyer, or Product...',
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Wholesaler Filter Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedWholesalerId,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              items: [
                                const DropdownMenuItem(value: 0, child: Text('All Sellers')),
                                ..._wholesalers.map((w) {
                                  return DropdownMenuItem(
                                    value: w['id'] as int,
                                    child: Text(
                                      w['name'] ?? 'Seller',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
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
                      ),
                      const SizedBox(width: 12),
                      // Status Filter Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              items: const [
                                DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                                DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedStatus = val ?? 'All';
                                  _applyFilters();
                                });
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

            // --- MAIN LIST / BODY ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No Matching Orders Found',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try refining your search keyword or active status flags.',
                                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final id = order['id'];
                            final buyerName = order['buyer_name'] ?? 'Buyer';
                            final address = order['shipping_address'] ?? 'N/A';
                            final phone = order['phone'] ?? 'N/A';
                            final totalAmount = (order['total_amount'] ?? 0.0).toDouble();
                            final paymentMethod = (order['payment_method'] ?? 'cash').toString().toUpperCase();
                            final date = order['created_at'] != null 
                                ? order['created_at'].toString().split('T')[0] 
                                : '';

                            // Parse items list
                            List<dynamic> itemsList = [];
                            if (order['items'] != null) {
                              if (order['items'] is String) {
                                try {
                                  itemsList = json.decode(order['items']);
                                } catch (_) {}
                              } else if (order['items'] is List) {
                                  itemsList = order['items'];
                              }
                            }

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
                                        Text(
                                          "Order #$id",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                                        ),
                                        if (date.isNotEmpty)
                                          Text(
                                            date,
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                                          ),
                                      ],
                                    ),
                                    const Divider(height: 20, color: AppTheme.border),
                                    
                                    // Buyer and details info
                                    Row(
                                      children: [
                                        const Text('Buyer: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                                        Text(buyerName, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Address: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                                        Expanded(
                                          child: Text(address, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('Contact: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                                        Text(phone, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Items sub-list header
                                    const Text(
                                      'Order Items:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // Render each item
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.background,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: itemsList.length,
                                        itemBuilder: (context, itemIdx) {
                                          final item = itemsList[itemIdx];
                                          final name = (item['name'] ?? 'Product').toString();
                                          final qty = int.tryParse(item['quantity'].toString()) ?? 1;
                                          final price = double.tryParse(item['price'].toString()) ?? 0.0;
                                          final wholesalerName = (item['wholesaler_name'] ?? 'Wholesaler').toString();
                                          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "$name (x$qty)",
                                                        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        "Seller: $wholesalerName",
                                                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  "Rs ${(price * qty).toStringAsFixed(0)}",
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Payment and Total info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.payment_rounded, size: 16, color: AppTheme.textSecondary),
                                            const SizedBox(width: 6),
                                            Text(
                                              paymentMethod,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "Total: Rs ${totalAmount.toStringAsFixed(0)}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
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