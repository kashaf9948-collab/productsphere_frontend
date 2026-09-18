import 'package:flutter/material.dart';

import '../../admin/services/admin_service.dart';

import '../../../core/theme/theme.dart';

import './widgets/admin_drawer.dart';

import './widgets/admin_bottom_nav.dart';

class AdminNegotiationsScreen extends StatefulWidget {
  const AdminNegotiationsScreen({super.key});

  @override
  State<AdminNegotiationsScreen> createState() =>
      _AdminNegotiationsScreenState();
}

class _AdminNegotiationsScreenState
    extends State<AdminNegotiationsScreen> {
  List<dynamic> _bids = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBids();
  }

  // ============================================================
  // SAFE DOUBLE CONVERSION
  // API may return:
  // 450
  // 450.00
  // "450"
  // "450.00"
  // null
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  // ============================================================
  // SAFE INT CONVERSION
  // ============================================================

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
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
      final data = await AdminService.fetchAdminBids();

      if (!mounted) return;

      setState(() {
        _bids = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch admin bids error: $e');

      if (!mounted) return;

      setState(() {
        _bids = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      drawer: const AdminDrawer(),

      bottomNavigationBar:
          const AdminBottomNav(activeIndex: -1),

      appBar: AppBar(
        backgroundColor: AppTheme.secondaryDark,

        title: const Text(
          'B2B Price Bids & Negotiations',
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed: _fetchBids,
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
                      padding:
                          const EdgeInsets.all(16),

                      itemCount: _bids.length,

                      separatorBuilder:
                          (context, index) =>
                              const SizedBox(
                        height: 12,
                      ),

                      itemBuilder:
                          (context, index) {
                        final bid =
                            _bids[index];

                        return _buildBidCard(
                          bid,
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
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.gavel_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          const Text(
            'No Negotiations Active',

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Active proposals in the platform will appear here.',

            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BID CARD
  // ============================================================

  Widget _buildBidCard(dynamic bid) {
    final name =
        bid['product_name'] ?? 'Product';

    final buyer =
        bid['buyer_name'] ?? 'Buyer';

    // ==========================================================
    // FIXED:
    // price can be "450.00"
    // ==========================================================

    final double originalPrice =
        _toDouble(
      bid['price'],
    );

    // ==========================================================
    // FIXED:
    // bid_price can be "450.00"
    // ==========================================================

    final double bidPrice =
        _toDouble(
      bid['bid_price'],
    );

    // ==========================================================
    // FIXED:
    // quantity can also arrive as String
    // ==========================================================

    final int qty =
        _toInt(
      bid['quantity'],
    );

    final String status =
        (bid['status'] ?? 'pending')
            .toString()
            .toLowerCase();

    final String? message =
        bid['message']?.toString();

    final String dateStr =
        bid['created_at'] != null
            ? bid['created_at']
                .toString()
                .split('T')[0]
            : '';

    Color badgeColor =
        AppTheme.pending;

    Color badgeBg =
        AppTheme.pendingLight;

    if (status == 'accepted') {
      badgeColor =
          AppTheme.active;

      badgeBg =
          AppTheme.activeLight;
    } else if (status == 'ordered') {
      badgeColor =
          Colors.blue;

      badgeBg =
          Colors.blue.shade50;
    } else if (status == 'rejected') {
      badgeColor =
          AppTheme.expired;

      badgeBg =
          AppTheme.expiredLight;
    }

    return Card(
      color: Colors.white,

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          AppTheme.radiusMd,
        ),

        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      margin: EdgeInsets.zero,

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ====================================================
            // PRODUCT + BUYER + STATUS
            // ====================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        name.toString(),

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme
                              .textPrimary,
                        ),

                        maxLines: 1,

                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        'Buyer: ${buyer.toString()}',

                        style:
                            const TextStyle(
                          fontSize: 12,
                          color: AppTheme
                              .textSecondary,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration:
                      BoxDecoration(
                    color: badgeBg,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: Text(
                    status.toUpperCase(),

                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 20,
              color: AppTheme.border,
            ),

            // ====================================================
            // PRICES + QUANTITY
            // ====================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [

                // ------------------------------------------------
                // BID PRICES
                // ------------------------------------------------

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      'Bid Proposal: Rs ${bidPrice.toStringAsFixed(0)}',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 14,
                        color:
                            AppTheme.secondary,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      'Regular Catalog: Rs ${originalPrice.toStringAsFixed(0)}',

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

                // ------------------------------------------------
                // QUANTITY + DATE
                // ------------------------------------------------

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .end,

                  children: [
                    Text(
                      'Lot Qty: $qty units',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),

                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(
                        height: 2,
                      ),

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
            // BUYER MESSAGE
            // ====================================================

            if (message != null &&
                message.trim().isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  10,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF8F9FA,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    AppTheme.radiusSm,
                  ),
                ),

                child: Text(
                  'Buyer Message: "$message"',

                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppTheme.textSecondary,
                    fontStyle:
                        FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}