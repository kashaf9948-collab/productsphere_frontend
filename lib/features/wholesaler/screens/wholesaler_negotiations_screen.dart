import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/wholesaler_service.dart';
import '../../../core/theme/theme.dart';
import './widgets/wholesaler_drawer.dart';
import './widgets/wholesaler_bottom_nav.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/snackbars.dart';

class WholesalerNegotiationsScreen extends StatefulWidget {
  const WholesalerNegotiationsScreen({super.key});

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
    final data = await WholesalerService.fetchWholesalerBids();
    setState(() {
      _bids = data;
      _isLoading = false;
    });
  }

 Future<void> _processStatusUpdate(
  int bidId,
  String status,
  String productName,
) async {
  // =========================================================
  // ACCEPT
  // =========================================================
  if (status == 'accepted') {
    final confirm = await showConfirmDialog(
      title: 'Accept Bid',
      content:
          'Are you sure you want to accept the price offer for "$productName"?',
      confirmText: 'Accept',
      confirmColor: AppTheme.active,
    );

    if (!confirm) return;

    showLoadingDialog(color: AppTheme.primary);

    final result = await WholesalerService.updateBidStatus(
      bidId,
      'accepted',
    );

    Get.back();

    if (result['success'] == true) {
      AppSnackbars.success(
        title: 'Offer Status Updated',
        message: 'The bid is now marked as accepted.',
      );

      _fetchBids();
    } else {
      AppSnackbars.error(
        title: 'Action Failed',
        message: result['message'] ?? 'Could not update status.',
      );
    }

    return;
  }

  // =========================================================
  // REJECT
  // =========================================================

  final TextEditingController messageController =
      TextEditingController();

  final formKey = GlobalKey<FormState>();

  final rejectionMessage = await Get.dialog<String>(
    AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      title: const Text(
        'Reject Bid',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to reject the price offer for "$productName"?',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Rejection Message *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: messageController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'Enter the reason for rejecting this bid...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusSm,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusSm,
                    ),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rejection message.';
                  }

                  if (value.trim().length < 3) {
                    return 'Message must be at least 3 characters.';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Get.back(
                result: messageController.text.trim(),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.expired,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppTheme.radiusSm,
              ),
            ),
          ),
          child: const Text(
            'Reject Bid',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );

  messageController.dispose();

  // User cancelled
  if (rejectionMessage == null ||
      rejectionMessage.trim().isEmpty) {
    return;
  }

  // =========================================================
  // SEND REJECTION + MESSAGE TO BACKEND
  // =========================================================

  showLoadingDialog(color: AppTheme.primary);

  final result = await WholesalerService.updateBidStatus(
    bidId,
    'rejected',
    rejectionMessage: rejectionMessage.trim(),
  );

  Get.back();

  if (result['success'] == true) {
    AppSnackbars.success(
      title: 'Bid Rejected',
      message: 'The bid was rejected and your message was sent.',
    );

    _fetchBids();
  } else {
    AppSnackbars.error(
      title: 'Action Failed',
      message: result['message'] ?? 'Could not reject the bid.',
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
        backgroundColor: AppTheme.primaryDark,
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
      badgeColor = AppTheme.primary;
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