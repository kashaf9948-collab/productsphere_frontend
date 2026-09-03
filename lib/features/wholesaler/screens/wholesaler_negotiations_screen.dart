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
  State<WholesalerNegotiationsScreen> createState() =>
      _WholesalerNegotiationsScreenState();
}

class _WholesalerNegotiationsScreenState
    extends State<WholesalerNegotiationsScreen> {
  List<dynamic> _bids = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchBids();
  }

  // ============================================================
  // SAFE NUMBER CONVERTERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().trim()) ?? 0;
  }

  String _toString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // FETCH BIDS
  // ============================================================

  Future<void> _fetchBids() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await WholesalerService.fetchWholesalerBids();

      if (!mounted) return;

      setState(() {
        _bids = data;
        _isLoading = false;
      });

      debugPrint('========================================');
      debugPrint('WHOLESALER BIDS RECEIVED');
      debugPrint('Total bids: ${_bids.length}');
      debugPrint('Data: $_bids');
      debugPrint('========================================');
    } catch (e) {
      debugPrint('❌ Fetch wholesaler bids error: $e');

      if (!mounted) return;

      setState(() {
        _bids = [];
        _isLoading = false;
      });

      AppSnackbars.error(
        title: 'Unable to Load Bids',
        message: 'Could not retrieve buyer bids. Please try again.',
      );
    }
  }

  // ============================================================
  // PROCESS ACCEPT / REJECT
  // ============================================================

  Future<void> _processStatusUpdate(
    int bidId,
    String status,
    String productName,
  ) async {
    if (_isProcessing) return;

    // ==========================================================
    // ACCEPT
    // ==========================================================

    if (status == 'accepted') {
      final confirm = await showConfirmDialog(
        title: 'Accept Bid',
        content:
            'Are you sure you want to accept the price offer for "$productName"?',
        confirmText: 'Accept',
        confirmColor: AppTheme.active,
      );

      if (!confirm) return;

      _isProcessing = true;

      showLoadingDialog(color: AppTheme.primary);

      try {
        final result = await WholesalerService.updateBidStatus(
          bidId,
          'accepted',
        );

        // Close loading dialog only if it exists.
        if (Get.isDialogOpen == true) {
          Get.back();
        }

        _isProcessing = false;

        if (result['success'] == true) {
          AppSnackbars.success(
            title: 'Offer Status Updated',
            message: 'The bid is now marked as accepted.',
          );

          await _fetchBids();
        } else {
          AppSnackbars.error(
            title: 'Action Failed',
            message:
                result['message']?.toString() ??
                'Could not update bid status.',
          );
        }
      } catch (e) {
        if (Get.isDialogOpen == true) {
          Get.back();
        }

        _isProcessing = false;

        debugPrint('❌ Accept bid error: $e');

        AppSnackbars.error(
          title: 'Action Failed',
          message: 'Something went wrong while accepting the bid.',
        );
      }

      return;
    }

    // ==========================================================
    // REJECT
    // ==========================================================

    final TextEditingController messageController =
        TextEditingController();

    final formKey = GlobalKey<FormState>();

    final rejectionMessage = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        title: const Text(
          'Reject Bid',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.textPrimary,
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusSm,
                      ),
                      borderSide: const BorderSide(
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

    // ==========================================================
    // SEND REJECTION TO BACKEND
    // ==========================================================

    _isProcessing = true;

    showLoadingDialog(color: AppTheme.primary);

    try {
      final result = await WholesalerService.updateBidStatus(
        bidId,
        'rejected',
        rejectionMessage: rejectionMessage.trim(),
      );

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      _isProcessing = false;

      if (result['success'] == true) {
        AppSnackbars.success(
          title: 'Bid Rejected',
          message:
              'The bid was rejected and your message was sent.',
        );

        await _fetchBids();
      } else {
        AppSnackbars.error(
          title: 'Action Failed',
          message:
              result['message']?.toString() ??
              'Could not reject the bid.',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      _isProcessing = false;

      debugPrint('❌ Reject bid error: $e');

      AppSnackbars.error(
        title: 'Action Failed',
        message:
            'Something went wrong while rejecting the bid.',
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

      drawer: const WholesalerDrawer(),

      bottomNavigationBar:
          const WholesalerBottomNav(activeIndex: 2),

      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Received Bids & Price Offers',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _fetchBids,
          ),
        ],
      ),

      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                ),
              )
            : _bids.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchBids,
                    color: AppTheme.primary,
                    child: ListView.separated(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _bids.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bid = _bids[index];

                        if (bid is! Map) {
                          return const SizedBox.shrink();
                        }

                        return _buildBidCard(
                          Map<String, dynamic>.from(bid),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchBids,
      color: AppTheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gavel_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'No Received Bids',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Buyer bids and price offers will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: _fetchBids,
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BID CARD
  // ============================================================

  Widget _buildBidCard(
    Map<String, dynamic> bid,
  ) {
    final int id = _toInt(bid['id']);

    final String productName = _toString(
      bid['product_name'],
      fallback: 'Product',
    );

    final String buyerName = _toString(
      bid['buyer_name'],
      fallback: 'Buyer',
    );

    final double originalPrice =
        _toDouble(bid['price']);

    final double bidPrice =
        _toDouble(bid['bid_price']);

    final int qty =
        _toInt(bid['quantity']);

    final String status = _toString(
      bid['status'],
      fallback: 'pending',
    ).toLowerCase();

    final String message = _toString(
      bid['message'],
    );

    final String dateStr =
        _formatDate(bid['created_at']);

    // ==========================================================
    // STATUS COLORS
    // ==========================================================

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

    final bool isPending = status == 'pending';

    // ==========================================================
    // CARD
    // ==========================================================

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppTheme.radiusMd,
        ),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ====================================================
            // PRODUCT + STATUS
            // ====================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color:
                                AppTheme.textSecondary,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              'Buyer: $buyerName',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    AppTheme.textSecondary,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 24,
              color: AppTheme.border,
            ),

            // ====================================================
            // PRICE + QUANTITY
            // ====================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Buyer Offer',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Rs ${bidPrice.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                          color:
                              AppTheme.primary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Catalog: Rs ${originalPrice.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              AppTheme.textHint,
                          decoration:
                              TextDecoration
                                  .lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,

                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$qty units',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 14,
                        color:
                            AppTheme.textSecondary,
                      ),
                    ),

                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 5),

                      Text(
                        dateStr,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // ====================================================
            // MESSAGE
            // ====================================================

            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF8F9FA),
                  borderRadius:
                      BorderRadius.circular(
                    AppTheme.radiusSm,
                  ),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buyer Message',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      message,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme.textSecondary,
                        fontStyle:
                            FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ====================================================
            // ACCEPT / REJECT
            // ====================================================

            if (isPending) ...[
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,

                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing
                          ? null
                          : () =>
                              _processStatusUpdate(
                                id,
                                'rejected',
                                productName,
                              ),

                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            AppTheme.expired,
                        side:
                            const BorderSide(
                          color:
                              AppTheme.expired,
                        ),
                        minimumSize:
                            const Size(0, 42),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                      ),

                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () =>
                              _processStatusUpdate(
                                id,
                                'accepted',
                                productName,
                              ),

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.active,
                        foregroundColor:
                            Colors.white,
                        minimumSize:
                            const Size(0, 42),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                      ),

                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final String raw =
        value.toString().trim();

    if (raw.isEmpty || raw == 'null') {
      return '';
    }

    try {
      final DateTime date =
          DateTime.parse(raw).toLocal();

      final String day =
          date.day.toString().padLeft(2, '0');

      final String month =
          date.month.toString().padLeft(2, '0');

      final String year =
          date.year.toString();

      return '$day-$month-$year';
    } catch (_) {
      // If backend sends another date format,
      // show the original value instead of crashing.
      return raw.split('T').first;
    }
  }
}