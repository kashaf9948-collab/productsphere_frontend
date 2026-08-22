import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../theme/theme.dart';
import 'package:kashaf_frontend/features/buyer/services/buyer_service.dart';
import './snackbars.dart';

// Standalone loading loader dialog
void showLoadingDialog({Color color = AppTheme.primary}) {
  Get.dialog(
    Center(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: color),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

// Standalone confirmation prompt dialog
Future<bool> showConfirmDialog({
  required String title,
  required String content,
  String confirmText = 'Delete',
  Color confirmColor = AppTheme.expired,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
      content: Text(
        content,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(90, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

// B2B Price Negotiation Bid Dialog
void showBidDialog({
  required BuildContext context,
  required Map<String, dynamic> product,
  required VoidCallback onSuccess,
}) async {
  final name = product['name'] ?? '';
  final catalogPrice = (product['price'] ?? 0.0).toDouble();
  final productId = product['id'] as int;
  final wholesalerId = product['wholesaler_id'] as int;

  // Show loading indicator while checking history
  showLoadingDialog();

  final box = GetStorage();
  final publicSettings = box.read('public_settings') ?? {};
  final maxRounds = int.tryParse(publicSettings['max_negotiation_rounds'] ?? '3') ?? 3;

  List<dynamic> bids = [];
  try {
    bids = await BuyerService.fetchBuyerBids();
  } catch (e) {
    print('Failed to check bids: $e');
  }
  Get.back(); // close loading dialog

  final productBids = bids.where((b) => b['product_id'] == productId).toList();
  if (productBids.length >= maxRounds) {
    AppSnackbars.warning(
      title: "Negotiation Limit",
      message: "You have reached the maximum of $maxRounds negotiations allowed for this product.",
    );
    return;
  }

  final priceController = TextEditingController(text: catalogPrice.toStringAsFixed(0));
  final qtyController = TextEditingController(text: '1');
  final msgController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      title: Text('Submit Price Offer\n$name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Proposed Price / Unit *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Proposed Price'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Price is required';
                if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text('Quantity (Lot size) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextFormField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 50, 100'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Quantity is required';
                if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Enter a valid quantity';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text('Additional Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextFormField(
              controller: msgController,
              decoration: const InputDecoration(hintText: 'e.g. Proposing deal for quick delivery'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
          ),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Get.back(); // close input dialog

            showLoadingDialog();
            final result = await BuyerService.submitBid(
              productId: productId,
              productName: name,
              originalPrice: catalogPrice,
              quantity: int.parse(qtyController.text.trim()),
              bidPrice: double.parse(priceController.text.trim()),
              wholesalerId: wholesalerId,
              message: msgController.text.trim(),
            );
            Get.back(); // close loader

            if (result['success']) {
              AppSnackbars.success(
                title: "Bid Submitted",
                message: "Your wholesale price offer has been sent to the seller.",
              );
              onSuccess();
            } else {
              AppSnackbars.error(
                title: "Bid Failed",
                message: result['message'] ?? "Could not submit bid.",
              );
            }
          },
          child: const Text('Submit Offer'),
        ),
      ],
    ),
  );
}