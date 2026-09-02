import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../admin/services/admin_service.dart';
import '../../../core/theme/theme.dart';

class BuyerActivityScreen extends StatefulWidget {
  const BuyerActivityScreen({super.key});

  @override
  State<BuyerActivityScreen> createState() => _BuyerActivityScreenState();
}

class _BuyerActivityScreenState extends State<BuyerActivityScreen> {
  bool _isLoading = false;
  late Map<String, dynamic> _buyer;
  List<dynamic> _buyerOrders = [];
  List<dynamic> _buyerBids = [];

  @override
  void initState() {
    super.initState();
    _buyer = Get.arguments as Map<String, dynamic>;
    _fetchActivity();
  }

  Future<void> _fetchActivity() async {
    setState(() => _isLoading = true);
    
    // Fetch all platform orders and bids in parallel
    final results = await Future.wait([
      AdminService.fetchAdminOrders(),
      AdminService.fetchAdminBids(),
    ]);

    final allOrders = results[0];
    final allBids = results[1];

    final buyerId = _buyer['id'];

    setState(() {
      // Filter list on client-side to keep code simple & easy to explain
      _buyerOrders = allOrders.where((o) => o['buyer_id'] == buyerId).toList();
      _buyerBids = allBids.where((b) => b['buyer_id'] == buyerId).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _buyer['name'] ?? 'Buyer';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.secondaryDark,
          title: Text("$name's Activity Logs"),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Orders Placed'),
              Tab(icon: Icon(Icons.gavel_rounded), text: 'Price Proposals'),
            ],
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : TabBarView(
                  children: [
                    // Tab 1: Orders Placed
                    _buildOrdersTab(),
                    
                    // Tab 2: Price Proposals
                    _buildBidsTab(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_buyerOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Orders Placed Yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _buyerOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _buyerOrders[index];
        final id = order['id'];
        final total = (order['total_amount'] ?? 0.0).toDouble();
        final payMethod = (order['payment_method'] ?? 'cash').toString().toUpperCase();
        final status = (order['status'] ?? 'pending').toString().toUpperCase();
        final date = order['created_at'] != null 
            ? order['created_at'].toString().split('T')[0] 
            : '';

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
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status == 'COMPLETED' ? AppTheme.active : AppTheme.pending,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('Rs ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Method:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text(payMethod, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Date:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Text(date, style: const TextStyle(color: AppTheme.textHint, fontSize: 13)),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBidsTab() {
    if (_buyerBids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Bids Submitted Yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _buyerBids.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bid = _buyerBids[index];
        final productName = bid['product_name'] ?? 'Product';
        final bidPrice = (bid['bid_price'] ?? 0.0).toDouble();
        final catalogPrice = (bid['price'] ?? 0.0).toDouble();
        final qty = bid['quantity'] ?? 1;
        final status = (bid['status'] ?? 'pending').toString().toUpperCase();

        Color statusColor = AppTheme.pending;
        if (status == 'ACCEPTED') statusColor = AppTheme.active;
        if (status == 'ORDERED') statusColor = Colors.blue;
        if (status == 'REJECTED') statusColor = AppTheme.expired;

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
                        productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Proposed Bid Price:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('Rs ${bidPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Catalog List Price:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('Rs ${catalogPrice.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.textHint, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lot Quantity size:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('$qty units', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}