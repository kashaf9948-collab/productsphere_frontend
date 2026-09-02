import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/cart_controller.dart';
import '../services/buyer_service.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/snackbars.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // ============================================================
  // CART CONTROLLER
  // ============================================================

  late final CartController cart;

  // ============================================================
  // FORM CONTROLLERS
  // ============================================================

  final _formKey = GlobalKey<FormState>();

  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // ============================================================
  // PAYMENT
  // ============================================================

  String _selectedPaymentMethod = 'cash';

  // ============================================================
  // CHECKOUT
  // ============================================================

  bool _isSubmitting = false;

  // ============================================================
  // RECEIPT
  // ============================================================

  Uint8List? _receiptBytes;

  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    /*
     * IMPORTANT:
     * If CartController already exists, use the existing instance.
     *
     * If it does not exist, create it.
     *
     * permanent: true keeps the cart controller alive when navigating
     * between buyer screens.
     */

    if (Get.isRegistered<CartController>()) {
      cart = Get.find<CartController>();
    } else {
      cart = Get.put<CartController>(
        CartController(),
        permanent: true,
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK RECEIPT
  // ============================================================

  Future<void> _pickReceipt() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Upload Payment Receipt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // CAMERA
              // ==================================================

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera'),
                onTap: () async {
                  Navigator.pop(ctx);

                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );

                  if (picked != null) {
                    final bytes = await picked.readAsBytes();

                    if (!mounted) return;

                    setState(() {
                      _receiptBytes = bytes;
                    });
                  }
                },
              ),

              // ==================================================
              // GALLERY
              // ==================================================

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF546E7A),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select from photos'),
                onTap: () async {
                  Navigator.pop(ctx);

                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );

                  if (picked != null) {
                    final bytes = await picked.readAsBytes();

                    if (!mounted) return;

                    setState(() {
                      _receiptBytes = bytes;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CHECKOUT
  // ============================================================

  Future<void> _processCheckout() async {
    // Prevent double submission
    if (_isSubmitting) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Online payment requires receipt
    if (_selectedPaymentMethod == 'online' &&
        _receiptBytes == null) {
      AppSnackbars.warning(
        title: "Receipt Required",
        message: "Please upload your payment receipt proof.",
      );

      return;
    }

    // Prevent checkout with empty cart
    if (cart.cartItems.isEmpty) {
      AppSnackbars.warning(
        title: "Cart Empty",
        message: "Please add products to your cart first.",
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ========================================================
      // PREPARE ORDER ITEMS
      // ========================================================

      final List<Map<String, dynamic>> orderItems = [];

      cart.cartItems.forEach((id, item) {
        final product =
            item['product'] as Map<String, dynamic>;

        final quantity =
            item['quantity'] as int;

        final rawPrice = product['price'];

        final double price =
            rawPrice is num
                ? rawPrice.toDouble()
                : double.tryParse(
                      rawPrice?.toString() ?? '0',
                    ) ??
                    0.0;

        orderItems.add({
          'product_id': id,
          'name': product['name'] ?? '',
          'price': price,
          'quantity': quantity,
          'wholesaler_id': product['wholesaler_id'],
          'wholesaler_name':
              product['wholesaler_name'] ?? 'Wholesaler',
        });
      });

      // ========================================================
      // RECEIPT BASE64
      // ========================================================

      final String? receiptBase64 =
          _receiptBytes != null
              ? base64Encode(_receiptBytes!)
              : null;

      // ========================================================
      // CHECKOUT API
      // ========================================================

      final result = await BuyerService.checkout(
        shippingAddress:
            _addressController.text.trim(),

        phone:
            _phoneController.text.trim(),

        paymentMethod:
            _selectedPaymentMethod,

        items:
            orderItems,

        totalAmount:
            cart.totalAmount,

        paymentProof:
            receiptBase64,
      );

      // ========================================================
      // CHECK RESULT
      // ========================================================

      if (!mounted) return;

      if (result['success'] == true) {
        // Clear cart
        cart.clearCart();

        AppSnackbars.success(
          title: "Order Placed",
          message:
              "Your wholesale order has been placed successfully!",
        );

        // Redirect
        Get.offAllNamed('/dashboard');
      } else {
        AppSnackbars.error(
          title: "Checkout Failed",
          message:
              result['message'] ??
                  "An error occurred during checkout.",
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppSnackbars.error(
        title: "Checkout Error",
        message:
            "Something went wrong. Please try again.",
      );

      debugPrint(
        "Checkout Error: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: const Text(
          'Your Cart & Checkout',
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Obx(() {
        // ======================================================
        // EMPTY CART
        // ======================================================

        if (cart.cartItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppTheme.textHint,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Your Cart is Empty",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Browse the marketplace catalog and add bulk items to your cart to checkout.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.primaryDark,
                      minimumSize:
                          const Size(200, 48),
                    ),
                    child: const Text(
                      "Go to Marketplace",
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ======================================================
        // CART + CHECKOUT
        // ======================================================

        return Column(
          children: [
            // ==================================================
            // CART ITEMS
            // ==================================================

            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.all(16),

                itemCount:
                    cart.cartItems.length,

                separatorBuilder:
                    (context, index) =>
                        const SizedBox(height: 12),

                itemBuilder:
                    (context, index) {
                  final id =
                      cart.cartItems.keys
                          .elementAt(index);

                  final item =
                      cart.cartItems[id]!;

                  final product =
                      item['product']
                          as Map<String, dynamic>;

                  final quantity =
                      item['quantity'] as int;

                  // Safe price conversion
                  final rawPrice =
                      product['price'];

                  final double price =
                      rawPrice is num
                          ? rawPrice.toDouble()
                          : double.tryParse(
                                rawPrice
                                        ?.toString() ??
                                    '0',
                              ) ??
                              0.0;

                  return Card(
                    color: Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        AppTheme.radiusMd,
                      ),
                      side:
                          const BorderSide(
                        color: AppTheme.border,
                        width: 0.5,
                      ),
                    ),

                    elevation: 0,

                    margin:
                        EdgeInsets.zero,

                    child: Padding(
                      padding:
                          const EdgeInsets.all(14),

                      child: Row(
                        children: [
                          // ====================================
                          // PRODUCT DETAILS
                          // ====================================

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name']
                                          ?.toString() ??
                                      '',
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        AppTheme.textPrimary,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  "Wholesaler: ${product['wholesaler_name'] ?? 'N/A'}",
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTheme.textSecondary,
                                  ),
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                Text(
                                  "Rs ${price.toStringAsFixed(0)} / unit",
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          // ====================================
                          // QUANTITY CONTROLS
                          // ====================================

                          Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity:
                                    VisualDensity.compact,
                                icon:
                                    const Icon(
                                  Icons
                                      .remove_circle_outline,
                                  color:
                                      AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  cart
                                      .decrementQuantity(
                                    id,
                                  );
                                },
                              ),

                              Container(
                                constraints:
                                    const BoxConstraints(
                                  minWidth: 35,
                                ),
                                alignment:
                                    Alignment.center,
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration:
                                    BoxDecoration(
                                  border:
                                      Border.all(
                                    color:
                                        AppTheme.border,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  "$quantity",
                                  style:
                                      const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),

                              IconButton(
                                visualDensity:
                                    VisualDensity.compact,
                                icon:
                                    const Icon(
                                  Icons
                                      .add_circle_outline,
                                  color:
                                      AppTheme.primary,
                                ),
                                onPressed: () {
                                  cart.addToCart(
                                    product,
                                  );
                                },
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

            // ==================================================
            // CHECKOUT PANEL
            // ==================================================

            Container(
              decoration: BoxDecoration(
                color: Colors.white,

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 10,
                    offset:
                        const Offset(0, -3),
                  ),
                ],

                borderRadius:
                    const BorderRadius.only(
                  topLeft:
                      Radius.circular(
                    AppTheme.radiusLg,
                  ),
                  topRight:
                      Radius.circular(
                    AppTheme.radiusLg,
                  ),
                ),
              ),

              child: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(20),

                  child: Form(
                    key: _formKey,

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        // ======================================
                        // CHECKOUT TITLE
                        // ======================================

                        const Text(
                          "Order Checkout",
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppTheme.textPrimary,
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ======================================
                        // ADDRESS
                        // ======================================

                        const Text(
                          'Shipping Address *',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                              _addressController,

                          maxLines: 2,

                          decoration:
                              const InputDecoration(
                            hintText:
                                'Enter complete business / warehouse delivery address',
                          ),

                          validator: (value) {
                            if (value ==
                                    null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return
                                  'Shipping address is required';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ======================================
                        // PHONE
                        // ======================================

                        const Text(
                          'Contact Phone *',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        TextFormField(
                          controller:
                              _phoneController,

                          keyboardType:
                              TextInputType.phone,

                          decoration:
                              const InputDecoration(
                            hintText:
                                'Enter phone number for delivery updates',
                          ),

                          validator: (value) {
                            if (value ==
                                    null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return
                                  'Contact phone number is required';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ======================================
                        // PAYMENT METHOD
                        // ======================================

                        const Text(
                          'Payment Method *',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Row(
                          children: [
                            // ==================================
                            // CASH
                            // ==================================

                            Expanded(
                              child:
                                  GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod =
                                        'cash';

                                    _receiptBytes =
                                        null;
                                  });
                                },

                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 12,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    border:
                                        Border.all(
                                      color: _selectedPaymentMethod ==
                                              'cash'
                                          ? AppTheme
                                              .primary
                                          : AppTheme
                                              .border,
                                      width: 1.5,
                                    ),

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      AppTheme
                                          .radiusSm,
                                    ),

                                    color: _selectedPaymentMethod ==
                                            'cash'
                                        ? AppTheme
                                            .primaryLight
                                        : Colors
                                            .white,
                                  ),

                                  child:
                                      Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Icon(
                                        Icons
                                            .money_rounded,
                                        color: _selectedPaymentMethod ==
                                                'cash'
                                            ? AppTheme
                                                .primary
                                            : AppTheme
                                                .textSecondary,
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      Text(
                                        "Cash",
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: _selectedPaymentMethod ==
                                                  'cash'
                                              ? AppTheme
                                                  .primary
                                              : AppTheme
                                                  .textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            // ==================================
                            // ONLINE
                            // ==================================

                            Expanded(
                              child:
                                  GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod =
                                        'online';
                                  });
                                },

                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 12,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    border:
                                        Border.all(
                                      color: _selectedPaymentMethod ==
                                              'online'
                                          ? AppTheme
                                              .primary
                                          : AppTheme
                                              .border,
                                      width: 1.5,
                                    ),

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      AppTheme
                                          .radiusSm,
                                    ),

                                    color: _selectedPaymentMethod ==
                                            'online'
                                        ? AppTheme
                                            .primaryLight
                                        : Colors
                                            .white,
                                  ),

                                  child:
                                      Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Icon(
                                        Icons
                                            .credit_card_rounded,
                                        color: _selectedPaymentMethod ==
                                                'online'
                                            ? AppTheme
                                                .primary
                                            : AppTheme
                                                .textSecondary,
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      Text(
                                        "Online",
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: _selectedPaymentMethod ==
                                                  'online'
                                              ? AppTheme
                                                  .primary
                                              : AppTheme
                                                  .textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ======================================
                        // ONLINE PAYMENT
                        // ======================================

                        if (_selectedPaymentMethod ==
                            'online') ...[
                          const SizedBox(
                            height: 14,
                          ),

                          Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets.all(
                              12,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFE0F2F1,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                AppTheme
                                    .radiusMd,
                              ),

                              border:
                                  Border.all(
                                color:
                                    AppTheme
                                        .primary
                                        .withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),

                            child: Row(
                              children: [
                                const Icon(
                                  Icons
                                      .info_outline_rounded,
                                  color:
                                      AppTheme
                                          .primary,
                                  size: 20,
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: const [
                                      Text(
                                        "JazzCash Number: 0300-1234567",
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              13,
                                          color:
                                              AppTheme
                                                  .textPrimary,
                                        ),
                                      ),

                                      SizedBox(
                                        height: 2,
                                      ),

                                      Text(
                                        "Account Title: Product Sphere B2B",
                                        style:
                                            TextStyle(
                                          fontSize:
                                              12,
                                          color:
                                              AppTheme
                                                  .textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          const Text(
                            'Upload Payment Receipt *',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          GestureDetector(
                            onTap:
                                _pickReceipt,

                            child:
                                Container(
                              height: 120,

                              width:
                                  double.infinity,

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF1F4F6,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  AppTheme
                                      .radiusMd,
                                ),

                                border:
                                    Border.all(
                                  color: _receiptBytes !=
                                          null
                                      ? AppTheme
                                          .primary
                                      : Colors
                                          .grey
                                          .shade300,

                                  width: _receiptBytes !=
                                          null
                                      ? 1.5
                                      : 1,
                                ),
                              ),

                              child:
                                  _receiptBytes !=
                                          null
                                      ? Stack(
                                          fit: StackFit
                                              .expand,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                AppTheme
                                                    .radiusMd -
                                                    1,
                                              ),

                                              child:
                                                  Image
                                                      .memory(
                                                _receiptBytes!,
                                                fit: BoxFit
                                                    .cover,
                                              ),
                                            ),

                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child:
                                                  CircleAvatar(
                                                radius:
                                                    12,
                                                backgroundColor:
                                                    AppTheme
                                                        .primary,
                                                child:
                                                    const Icon(
                                                  Icons
                                                      .check_rounded,
                                                  size:
                                                      14,
                                                  color:
                                                      Colors.white,
                                                ),
                                              ),
                                            ),

                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child:
                                                  Container(
                                                decoration:
                                                    BoxDecoration(
                                                  color:
                                                      Colors.black.withValues(
                                                    alpha:
                                                        0.45,
                                                  ),
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                    bottom:
                                                        Radius.circular(
                                                      AppTheme
                                                          .radiusMd -
                                                          1,
                                                    ),
                                                  ),
                                                ),

                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  vertical:
                                                      4,
                                                ),

                                                child:
                                                    const Text(
                                                  'Tap to change receipt',
                                                  textAlign:
                                                      TextAlign
                                                          .center,
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.white,
                                                    fontSize:
                                                        11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                          children: const [
                                            Icon(
                                              Icons
                                                  .add_photo_alternate_outlined,
                                              color:
                                                  AppTheme
                                                      .primary,
                                              size:
                                                  30,
                                            ),

                                            SizedBox(
                                              height:
                                                  6,
                                            ),

                                            Text(
                                              'Tap to upload receipt proof',
                                              style:
                                                  TextStyle(
                                                color:
                                                    AppTheme
                                                        .textSecondary,
                                                fontSize:
                                                    12,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                            ),

                                            SizedBox(
                                              height:
                                                  2,
                                            ),

                                            Text(
                                              'Camera or Gallery',
                                              style:
                                                  TextStyle(
                                                color:
                                                    AppTheme
                                                        .textHint,
                                                fontSize:
                                                    10,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 20,
                        ),

                        // ======================================
                        // TOTAL
                        // ======================================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              "Total Amount:",
                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color: AppTheme
                                    .textSecondary,
                              ),
                            ),

                            Text(
                              "Rs ${cart.totalAmount.toStringAsFixed(0)}",
                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color: AppTheme
                                    .primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // ======================================
                        // CHECKOUT BUTTON
                        // ======================================

                        SizedBox(
                          width:
                              double.infinity,
                          height: 50,
                          child: _isSubmitting
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(
                                    color: AppTheme
                                        .primary,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed:
                                      _processCheckout,

                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        AppTheme
                                            .primaryDark,
                                  ),

                                  child:
                                      const Text(
                                    "Confirm Order & Checkout",
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}