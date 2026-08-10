import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/wholesaler_drawer.dart';
import '../../core/widgets/wholesaler_bottom_nav.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/snackbars.dart';

class WholesalerNegotiationsScreen extends StatefulWidget {
  const WholesalerNegotiationsScreen({Key? key}) : super(key: key);

  @override
  State<WholesalerNegotiationsScreen> createState() => _WholesalerNegotiationsScreenState();
}

class _WholesalerNegotiationsScreenState extends State<WholesalerNegotiationsScreen> {
  List<dynamic> _bids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBids();
  }

  Future<void> _fetchBids() async {
    setState(() => _isLoading = true);
    final data = await ProductService.fetchWholesalerBids();
    setState(() {
      _bids = data;
      _isLoading = false;
    });
  }

  Future<void> _processStatusUpdate(int bidId, String status, String productName) async {
    final confirm = await showConfirmDialog(
      title: '${status == 'accepted' ? 'Accept' : 'Reject'} Bid',
      content: 'Are you sure you want to $status the price offer for "$productName"?',
      confirmText: status.capitalizeFirst!,
      confirmColor: status == 'accepted' ? AppTheme.active : AppTheme.expired,
    );

    if (!confirm) return;

    showLoadingDialog(color: AppTheme.primary);
    final result = await ProductService.updateBidStatus(bidId, status);
    Get.back(); // close loader

    if (result['success']) {
      if (status == 'accepted') {
        AppSnackbars.success(
          title: "Offer Status Updated",
          message: "The bid is now marked as accepted.",
        );
      } else {
        AppSnackbars.error(
          title: "Offer Status Updated",
          message: "The bid is now marked as rejected.",
        );
      }
      _fetchBids();
    } else {
      AppSnackbars.error(
        title: "Action Failed",
        message: result['message'] ?? "Could not update status.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const WholesalerDrawer(),
      bottomNavigationBar: const WholesalerBottomNav(activeIndex: 2),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Received Bids & Price Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchBids,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _bids.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchBids,
                    color: AppTheme.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bids.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bid = _bids[index];
                        return _buildBidCard(bid);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Received Bids',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buyers bids and counter-offers will appear here.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBidCard(dynamic bid) {
    final int id = bid['id'];
    final name = bid['product_name'] ?? 'Product';
    final buyer = bid['buyer_name'] ?? 'Buyer';
    final double originalPrice = (bid['price'] ?? 0.0).toDouble();
    final double bidPrice = (bid['bid_price'] ?? 0.0).toDouble();
    final int qty = bid['quantity'] ?? 1;
    final String status = (bid['status'] ?? 'pending').toString().toLowerCase();
    final String? message = bid['message'];
    final String dateStr = bid['created_at'] != null 
        ? bid['created_at'].toString().split('T')[0] 
        : '';

    Color badgeColor = AppTheme.pending;
    Color badgeBg = AppTheme.pendingLight;
    if (status == 'accepted') {
      badgeColor = AppTheme.active;
      badgeBg = AppTheme.activeLight;
    } else if (status == 'ordered') {
      badgeColor = Colors.blue;
      badgeBg = Colors.blue.shade50;
    } else if (status == 'rejected') {
      badgeColor = AppTheme.expired;
      badgeBg = AppTheme.expiredLight;
    }

    final isPending = status == 'pending';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Buyer: $buyer',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppTheme.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bid Price: Rs ${bidPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Catalog Price: Rs ${originalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Lot Qty: $qty units',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (message != null && message.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'Message: "$message"',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _processStatusUpdate(id, 'rejected', name),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.expired,
                      side: const BorderSide(color: AppTheme.expired),
                      minimumSize: const Size(90, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _processStatusUpdate(id, 'accepted', name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.active,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(90, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}