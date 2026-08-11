import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/cart_controller.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/snackbars.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedPaymentMethod = 'cash'; // 'cash' or 'online'
  bool _isSubmitting = false;

  Uint8List? _receiptBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickReceipt() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Upload Payment Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.primary, child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() { _receiptBytes = bytes; });
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF546E7A), child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 20)),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from photos'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() { _receiptBytes = bytes; });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout(CartController cart) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaymentMethod == 'online' && _receiptBytes == null) {
      AppSnackbars.warning(
        title: "Receipt Required",
        message: "Please upload your payment receipt proof.",
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Prepare items list
    final List<Map<String, dynamic>> orderItems = [];
    cart.cartItems.forEach((id, item) {
      final p = item['product'] as Map<String, dynamic>;
      final qty = item['quantity'] as int;
      orderItems.add({
        'product_id': id,
        'name': p['name'],
        'price': (p['price'] as num).toDouble(),
        'quantity': qty,
        'wholesaler_id': p['wholesaler_id'],
        'wholesaler_name': p['wholesaler_name'] ?? 'Wholesaler',
      });
    });

    final String? receiptBase64 = _receiptBytes != null ? base64Encode(_receiptBytes!) : null;

    final result = await ProductService.checkout(
      shippingAddress: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      items: orderItems,
      totalAmount: cart.totalAmount,
      paymentProof: receiptBase64,
    );

    setState(() => _isSubmitting = false);

    if (result['success']) {
      // Clear Cart
      cart.clearCart();

      AppSnackbars.success(
        title: "Order Placed",
        message: "Your wholesale order has been placed successfully!",
      );

      // Redirect back to dashboard
      Get.offAllNamed('/dashboard');
    } else {
      AppSnackbars.error(
        title: "Checkout Failed",
        message: result['message'] ?? "An error occurred during checkout.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('Your Cart & Checkout'),
      ),
      body: Obx(() {
        if (cart.cartItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your Cart is Empty",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Browse the marketplace catalog and add bulk items to your cart to checkout.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      minimumSize: const Size(200, 48),
                    ),
                    child: const Text("Go to Marketplace"),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Cart Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.cartItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final id = cart.cartItems.keys.elementAt(index);
                  final item = cart.cartItems[id]!;
                  final p = item['product'] as Map<String, dynamic>;
                  final qty = item['quantity'] as int;
                  final price = (p['price'] as num).toDouble();

                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      side: const BorderSide(color: AppTheme.border, width: 0.5),
                    ),
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] ?? '',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Wholesaler: ${p['wholesaler_name'] ?? 'N/A'}",
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Rs ${price.toStringAsFixed(0)} / unit",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Controls
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary),
                                onPressed: () => cart.decrementQuantity(id),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Text(
                                  "$qty",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                onPressed: () => cart.addToCart(p),
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

            // Checkout Panel
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  )
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  topRight: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Checkout",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 14),

                        // Address field
                        const Text('Shipping Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            hintText: 'Enter complete business / warehouse delivery address',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Shipping address is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone field
                        const Text('Contact Phone *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Enter phone number for delivery updates',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Contact phone number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Payment Methods
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
                                      color: _selectedPaymentMethod == 'cash'
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    color: _selectedPaymentMethod == 'cash'
                                        ? AppTheme.primaryLight
                                        : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.money_rounded,
                                        color: _selectedPaymentMethod == 'cash'
                                            ? AppTheme.primary
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Cash",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _selectedPaymentMethod == 'cash'
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary,
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
                                      color: _selectedPaymentMethod == 'online'
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    color: _selectedPaymentMethod == 'online'
                                        ? AppTheme.primaryLight
                                        : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.credit_card_rounded,
                                        color: _selectedPaymentMethod == 'online'
                                            ? AppTheme.primary
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Online",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _selectedPaymentMethod == 'online'
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedPaymentMethod == 'online') ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "JazzCash Number: 0300-1234567",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "Account Title: Product Sphere B2B",
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('Upload Payment Receipt *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickReceipt,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F6),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: _receiptBytes != null ? AppTheme.primary : Colors.grey.shade300,
                                  width: _receiptBytes != null ? 1.5 : 1,
                                ),
                              ),
                              child: _receiptBytes != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1),
                                          child: Image.memory(_receiptBytes!, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 6, right: 6,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: AppTheme.primary,
                                            child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0, left: 0, right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.45),
                                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusMd - 1)),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: const Text('Tap to change receipt', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 30),
                                        SizedBox(height: 6),
                                        Text('Tap to upload receipt proof', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 2),
                                        Text('Camera or Gallery', style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Totals info and Submit Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Amount:",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                            Text(
                              "Rs ${cart.totalAmount.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _isSubmitting
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                            : ElevatedButton(
                                onPressed: () => _processCheckout(cart),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDark,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text("Confirm Order & Checkout"),
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