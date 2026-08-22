import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/theme/theme.dart';
import '../services/buyer_service.dart';
import '../../wholesaler/services/wholesaler_service.dart';
import '../../buyer/screens/widgets/client_drawer.dart';
import '../../wholesaler/screens/widgets/wholesaler_drawer.dart';
import '../../buyer/screens/widgets/client_bottom_nav.dart';
import '../../wholesaler/screens/widgets/wholesaler_bottom_nav.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/dialogs.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  late String _role;

  String _searchQuery = '';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final box = GetStorage();
    _role = box.read('role') ?? 'buyer';
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> list = [];
      if (_role.toLowerCase() == 'wholesaler') {
        list = await WholesalerService.fetchWholesalerOrders();
      } else {
        list = await BuyerService.fetchBuyerOrders();
      }
      setState(() {
        _allOrders = list;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      print('Fetch orders history error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        if (order == null) return false;
        final idStr = "#${order['id'] ?? ''}";
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
            itemsList = List<dynamic>.from(order['items']);
          }
        }
        itemsList = itemsList.where((it) => it != null).toList();

        // Search matches Order ID, Buyer Name, or Product Name
        final matchesSearch = _searchQuery.isEmpty ||
            idStr.contains(_searchQuery) ||
            buyerName.contains(_searchQuery.toLowerCase()) ||
            itemsList.any((item) => (item['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()));

        // Status match
        final matchesStatus = _selectedStatus == 'All' ||
            status == _selectedStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final success = await WholesalerService.updateOrderStatus(orderId, newStatus);
    if (success) {
      AppSnackbars.success(
        title: 'Status Updated',
        message: 'Order status successfully changed to $newStatus.',
      );
      _fetchOrders();
    } else {
      AppSnackbars.error(
        title: 'Update Failed',
        message: 'Failed to update order status.',
      );
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirm = await showConfirmDialog(
      title: 'Cancel Order',
      content: 'Are you sure you want to cancel this order? This action cannot be undone.',
      confirmText: 'Yes, Cancel',
      confirmColor: AppTheme.expired,
    );
    if (!confirm) return;

    final success = await WholesalerService.updateOrderStatus(orderId, 'cancelled');
    if (success) {
      AppSnackbars.success(
        title: 'Order Cancelled',
        message: 'Your order has been cancelled successfully.',
      );
      _fetchOrders();
    } else {
      AppSnackbars.error(
        title: 'Cancellation Failed',
        message: 'Could not cancel the order.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWholesaler = _role.toLowerCase() == 'wholesaler';

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: isWholesaler ? const WholesalerDrawer() : const ClientDrawer(),
      bottomNavigationBar: isWholesaler
          ? const WholesalerBottomNav(activeIndex: -1)
          : const ClientBottomNav(activeIndex: -1),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: Text(isWholesaler ? 'Incoming Purchase Orders' : 'My Placed Orders'),
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
                      hintText: isWholesaler
                          ? 'Search by Order #, Buyer, or Product...'
                          : 'Search by Order # or Product...',
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
                  // Status Dropdown — same as admin orders page
                  Container(
                    width: double.infinity,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                          DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                          DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
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
                              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _allOrders.isEmpty
                                    ? (isWholesaler ? 'No Incoming Orders Yet' : 'No Placed Orders Found')
                                    : 'No Matching Orders Found',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _allOrders.isEmpty
                                    ? (isWholesaler
                                        ? 'Incoming buyer checkouts will automatically appear here.'
                                        : 'Products you buy or negotiations you checkout will display here.')
                                    : 'Try refining your search keyword or selecting a different status.',
                                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
                            final buyerName = (order['buyer_name'] ?? 'Buyer').toString();
                            final address = (order['shipping_address'] ?? 'N/A').toString();
                            final phone = (order['phone'] ?? 'N/A').toString();
                            final totalAmount = double.tryParse((order['total_amount'] ?? 0.0).toString()) ?? 0.0;
                            final paymentMethod = (order['payment_method'] ?? 'cash').toString().toUpperCase();
                            final date = order['created_at'] != null 
                                ? order['created_at'].toString().split('T')[0] 
                                : '';
                            final status = (order['status'] ?? 'pending').toString().toLowerCase();
                            final String? paymentProof = order['payment_proof'];

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
                            itemsList = itemsList.where((it) => it != null).toList();

                            // Dynamic Status Chip Color
                            Color statusColor = Colors.orange;
                            if (status == 'shipped') statusColor = Colors.blue;
                            if (status == 'delivered') statusColor = Colors.green;
                            if (status == 'cancelled') statusColor = Colors.red;

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
                                    // Order Header Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Order #$id',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Placed on $date',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                    const Divider(height: 24, color: AppTheme.border),

                                    // Buyer details (for wholesalers)
                                    if (isWholesaler) ...[
                                      const Text(
                                        'SHIPPING DETAILS',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Buyer Name: $buyerName',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Address: $address',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Phone: $phone',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                      ),
                                      const Divider(height: 24, color: AppTheme.border),
                                    ],

                                    // Payment receipt preview (if online payment receipt is uploaded)
                                    if (isWholesaler && paymentProof != null && paymentProof.isNotEmpty) ...[
                                      const Text(
                                        'PAYMENT RECEIPT (ONLINE)',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    AppBar(
                                                      title: const Text('Receipt Screenshot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                                      backgroundColor: AppTheme.primary,
                                                      foregroundColor: Colors.white,
                                                      automaticallyImplyLeading: false,
                                                      actions: [
                                                        IconButton(
                                                          icon: const Icon(Icons.close),
                                                          onPressed: () => Navigator.pop(context),
                                                        )
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    SizedBox(
                                                      height: MediaQuery.of(context).size.height * 0.6,
                                                      child: InteractiveViewer(
                                                        child: Image.memory(
                                                          base64Decode(paymentProof),
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                          child: Image.memory(
                                            base64Decode(paymentProof),
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 120,
                                              color: Colors.grey.shade100,
                                              child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textHint)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Row(
                                        children: [
                                          Icon(Icons.zoom_in_rounded, size: 14, color: AppTheme.textHint),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tap to zoom / view full receipt screenshot',
                                            style: TextStyle(fontSize: 11, color: AppTheme.textHint, fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24, color: AppTheme.border),
                                    ],

                                    // Items list
                                    const Text(
                                      'ORDER ITEMS',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    ...itemsList.map((item) {
                                       final itemName = (item['name'] ?? 'Product').toString();
                                       final itemQty = int.tryParse(item['quantity'].toString()) ?? 1;
                                       final itemPrice = double.tryParse(item['price'].toString()) ?? 0.0;
                                       final itemSubtotal = itemQty * itemPrice;
                                       final wholesalerName = (item['wholesaler_name'] ?? 'Wholesaler').toString();

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$itemName x$itemQty',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Seller: $wholesalerName',
                                                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              'Rs $itemSubtotal',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    const Divider(height: 24, color: AppTheme.border),

                                    // Bottom Row (Payment + Price)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'PAYMENT METHOD',
                                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              paymentMethod,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'TOTAL AMOUNT',
                                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Rs $totalAmount',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Wholesaler dispatch actions
                                    if (isWholesaler && status != 'delivered' && status != 'cancelled') ...[
                                      const Divider(height: 24, color: AppTheme.border),
                                      if (status == 'pending')
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(id, 'shipped'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryDark,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                              ),
                                            ),
                                            icon: const Icon(Icons.local_shipping_outlined, size: 16),
                                            label: const Text('Mark as Shipped'),
                                          ),
                                        ),
                                      if (status == 'shipped')
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(id, 'delivered'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                              ),
                                            ),
                                            icon: const Icon(Icons.done_all_rounded, size: 16),
                                            label: const Text('Mark as Delivered'),
                                          ),
                                        ),
                                    ],

                                    // Buyer cancellation action (only if status is pending)
                                    if (!isWholesaler && status == 'pending') ...[
                                      const Divider(height: 24, color: AppTheme.border),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _cancelOrder(id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.expired,
                                            side: const BorderSide(color: AppTheme.expired),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                            ),
                                          ),
                                          icon: const Icon(Icons.cancel_outlined, size: 16),
                                          label: const Text('Cancel Order'),
                                        ),
                                      ),
                                    ],
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