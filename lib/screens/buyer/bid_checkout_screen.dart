import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/client_bottom_nav.dart';
import '../../core/widgets/snackbars.dart';

class BidCheckoutScreen extends StatefulWidget {
  const BidCheckoutScreen({Key? key}) : super(key: key);

  @override
  State<BidCheckoutScreen> createState() => _BidCheckoutScreenState();
}

class _BidCheckoutScreenState extends State<BidCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  bool _isSubmitting = false;

  late Map<String, dynamic> _bid;
  late double _bidPrice;
  late int _quantity;
  late double _subtotal;
  final double _shippingFee = 250.0;
  late double _commissionFee;
  late double _commPercent;
  late double _totalAmount;

  @override
  void initState() {
    super.initState();
    _bid = Get.arguments as Map<String, dynamic>;
    _bidPrice = (_bid['bid_price'] ?? 0.0).toDouble();
    _quantity = _bid['quantity'] ?? 1;
    _subtotal = _bidPrice * _quantity;

    final box = GetStorage();
    final settings = box.read('public_settings') ?? {};
    _commPercent = double.tryParse(settings['commission_percent']?.toString() ?? '5') ?? 5.0;
    _commissionFee = _subtotal * (_commPercent / 100.0);

    _totalAmount = _subtotal + _shippingFee + _commissionFee;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Prepare items list for checkout containing the negotiated details
    final List<Map<String, dynamic>> orderItems = [
      {
        'product_id': _bid['product_id'],
        'name': '${_bid['product_name']} (Negotiated Bid)',
        'price': _bidPrice,
        'quantity': _quantity,
        'wholesaler_id': _bid['wholesaler_id'],
        'wholesaler_name': _bid['wholesaler_name'] ?? 'Wholesaler',
      }
    ];

    // 1. Submit checkout order to backend
    final result = await ProductService.checkout(
      shippingAddress: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      items: orderItems,
      totalAmount: _totalAmount,
    );

    if (result['success']) {
      // 2. Mark this negotiation status as 'ordered'
      await ProductService.updateBidStatus(_bid['id'], 'ordered');

      setState(() => _isSubmitting = false);

      AppSnackbars.success(
        title: "Order Placed",
        message: "Your negotiated deal has been converted to an order successfully!",
      );

      // Redirect back to buyer negotiations log
      Get.offAllNamed('/dashboard');
    } else {
      setState(() => _isSubmitting = false);
      AppSnackbars.error(
        title: "Order Placement Failed",
        message: result['message'] ?? "An error occurred during checkout.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = _bid['product_name'] ?? 'Product';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Convert Bid to Order'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Info Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bid Details Summary
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Approved Deal Details',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const Divider(height: 20, color: AppTheme.border),
                            Text(
                              productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Negotiated Price:', style: TextStyle(color: AppTheme.textSecondary)),
                                Text('Rs ${_bidPrice.toStringAsFixed(0)} / unit', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Lot Size Quantity:', style: TextStyle(color: AppTheme.textSecondary)),
                                Text('$_quantity units', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Address Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shipping Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              hintText: 'Enter complete business / delivery address',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Shipping address is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text('Contact Phone Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 03211234567',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Contact phone is required';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Method Choice Card
                    const Text('Payment Method *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPaymentMethod = 'cash'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedPaymentMethod == 'cash' ? AppTheme.primary : AppTheme.border,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                color: _selectedPaymentMethod == 'cash' ? AppTheme.primaryLight : Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.money_rounded,
                                    color: _selectedPaymentMethod == 'cash' ? AppTheme.primary : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Cash",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedPaymentMethod == 'cash' ? AppTheme.primary : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPaymentMethod = 'online'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedPaymentMethod == 'online' ? AppTheme.primary : AppTheme.border,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                color: _selectedPaymentMethod == 'online' ? AppTheme.primaryLight : Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    color: _selectedPaymentMethod == 'online' ? AppTheme.primary : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Online Card",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedPaymentMethod == 'online' ? AppTheme.primary : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Summary Bottom Panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(color: AppTheme.textSecondary)),
                      Text('Rs ${_subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shipping Fee:', style: TextStyle(color: AppTheme.textSecondary)),
                      Text('Rs ${_shippingFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Platform Commission (${_commPercent.toStringAsFixed(0)}%):', style: const TextStyle(color: AppTheme.textSecondary)),
                      Text('Rs ${_commissionFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'Rs ${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : ElevatedButton(
                          onPressed: _processCheckout,
                          child: const Text('Place Negotiation Order'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}