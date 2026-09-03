import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/buyer_service.dart';
import '../../../core/theme/theme.dart';
import './widgets/client_drawer.dart';
import './widgets/client_bottom_nav.dart';

class NegotiationsListScreen extends StatefulWidget {
  const NegotiationsListScreen({super.key});

  @override
  State<NegotiationsListScreen> createState() =>
      _NegotiationsListScreenState();
}

class _NegotiationsListScreenState
    extends State<NegotiationsListScreen> {
  List<dynamic> _bids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBids();
  }

  // ============================================================
  // FETCH BIDS
  // ============================================================

  Future<void> _fetchBids() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final data = await BuyerService.fetchBuyerBids();

      if (!mounted) return;

      setState(() {
        _bids = data;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('FETCH BIDS ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _bids = [];
        _isLoading = false;
      });

      Get.snackbar(
        'Error',
        'Unable to load your sent bids.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    }
  }

  // ============================================================
  // SAFE DOUBLE CONVERTER
  // ============================================================
  //
  // API may return:
  //
  // 3000
  // "3000"
  // "3000.00"
  // 3000.00
  //
  // This safely converts all of them to double.
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0.0;
  }

  // ============================================================
  // SAFE INT CONVERTER
  // ============================================================

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  String _toStringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString();

    if (result.trim().isEmpty) {
      return fallback;
    }

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      drawer: const ClientDrawer(),

      bottomNavigationBar:
          const ClientBottomNav(
        activeIndex: 1,
      ),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,

        title: const Text(
          'My Sent Bids',
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed: _fetchBids,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

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

                      padding:
                          const EdgeInsets.all(16),

                      itemCount:
                          _bids.length,

                      separatorBuilder:
                          (context, index) =>
                              const SizedBox(
                        height: 12,
                      ),

                      itemBuilder:
                          (context, index) {
                        final bid = _bids[index];

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
    return RefreshIndicator(
      onRefresh: _fetchBids,

      color: AppTheme.primary,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.30,
          ),

          Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'No Negotiations Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 30,
                  ),

                  child: Text(
                    'Browse products and propose custom bulk deals.',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
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
    // Make sure API response is actually a Map
    if (bid is! Map) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // PRODUCT NAME
    // ==========================================================

    final String name = _toStringValue(
      bid['product_name'],
      fallback: 'Product',
    );

    // ==========================================================
    // ORIGINAL PRICE
    // ==========================================================
    //
    // FIX:
    //
    // OLD:
    // (bid['price'] ?? 0.0).toDouble()
    //
    // NEW:
    // _toDouble(bid['price'])
    //
    // ==========================================================

    final double originalPrice =
        _toDouble(
      bid['price'],
    );

    // ==========================================================
    // BID PRICE
    // ==========================================================

    final double bidPrice =
        _toDouble(
      bid['bid_price'],
    );

    // ==========================================================
    // QUANTITY
    // ==========================================================

    final int qty =
        _toInt(
      bid['quantity'],
    );

    // ==========================================================
    // STATUS
    // ==========================================================

    final String status =
        _toStringValue(
      bid['status'],
      fallback: 'pending',
    ).toLowerCase();

    // ==========================================================
    // MESSAGE
    // ==========================================================

    final String message =
        _toStringValue(
      bid['message'],
    );

    // ==========================================================
    // DATE
    // ==========================================================

    final String createdAt =
        _toStringValue(
      bid['created_at'],
    );

    final String dateStr =
        createdAt.isNotEmpty
            ? createdAt.split('T')[0]
            : '';

    // ==========================================================
    // STATUS COLORS
    // ==========================================================

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

    // ==========================================================
    // CARD
    // ==========================================================

    return Card(
      color: Colors.white,

      elevation: 0,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          AppTheme.radiusMd,
        ),

        side:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),

      margin:
          EdgeInsets.zero,

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // TOP ROW
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ==================================================
                // PRODUCT NAME
                // ==================================================

                Expanded(
                  child: Text(
                    name,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,

                      fontSize:
                          16,

                      color:
                          AppTheme.textPrimary,
                    ),

                    maxLines:
                        1,

                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // ==================================================
                // STATUS
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        badgeBg,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: Text(
                    status.toUpperCase(),

                    style:
                        TextStyle(
                      fontSize:
                          10,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          badgeColor,
                    ),
                  ),
                ),
              ],
            ),

            // ==================================================
            // DIVIDER
            // ==================================================

            const Divider(
              height: 20,
              color: AppTheme.border,
            ),

            // ==================================================
            // PRICE + QUANTITY
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                // ==================================================
                // PRICES
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        'Your Proposed: Rs ${bidPrice.toStringAsFixed(0)}',

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,

                          fontSize:
                              14,

                          color:
                              AppTheme.primary,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        'Regular Price: Rs ${originalPrice.toStringAsFixed(0)}',

                        style:
                            const TextStyle(
                          fontSize:
                              12,

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

                const SizedBox(
                  width: 10,
                ),

                // ==================================================
                // QUANTITY + DATE
                // ==================================================

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,

                  children: [

                    Text(
                      'Lot Qty: $qty units',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,

                        fontSize:
                            13,

                        color:
                            AppTheme.textSecondary,
                      ),
                    ),

                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        dateStr,

                        style:
                            const TextStyle(
                          fontSize:
                              11,

                          color:
                              AppTheme.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // ==================================================
            // MESSAGE
            // ==================================================

            if (message.trim().isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(10),

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
                  'Message: "$message"',

                  style:
                      const TextStyle(
                    fontSize:
                        12,

                    color:
                        AppTheme.textSecondary,

                    fontStyle:
                        FontStyle.italic,
                  ),
                ),
              ),
            ],

            // ==================================================
            // ACCEPTED → CONVERT TO ORDER
            // ==================================================

            if (status == 'accepted') ...[
              const SizedBox(
                height: 14,
              ),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,

                children: [

                  ElevatedButton(
                    onPressed: () {
                      Get.toNamed(
                        '/bid-checkout',
                        arguments: bid,
                      );
                    },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.primary,

                      foregroundColor:
                          Colors.white,

                      minimumSize:
                          const Size(
                        120,
                        36,
                      ),

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppTheme.radiusSm,
                        ),
                      ),
                    ),

                    child:
                        const Text(
                      'Convert to Order',

                      style:
                          TextStyle(
                        fontSize:
                            12,

                        fontWeight:
                            FontWeight.bold,
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
}