import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../theme/theme.dart';
import 'package:kashaf_frontend/features/buyer/services/buyer_service.dart';
import './snackbars.dart';


// ============================================================
// STANDALONE LOADING LOADER DIALOG
// ============================================================

void showLoadingDialog({
  Color color = AppTheme.primary,
}) {
  // Avoid opening multiple loading dialogs
  if (Get.isDialogOpen == true) {
    return;
  }

  Get.dialog(
    Center(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppTheme.radiusMd,
          ),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: color,
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}


// ============================================================
// STANDALONE CONFIRMATION PROMPT DIALOG
// ============================================================

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
        borderRadius: BorderRadius.circular(
          AppTheme.radiusMd,
        ),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),

      content: Text(
        content,
        style: const TextStyle(
          color: AppTheme.textSecondary,
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Get.back(result: false);
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
            Get.back(result: true);
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,

            minimumSize: const Size(
              90,
              40,
            ),

            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppTheme.radiusSm,
              ),
            ),
          ),

          child: Text(
            confirmText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}


// ============================================================
// B2B PRICE NEGOTIATION BID DIALOG
// ============================================================

void showBidDialog({
  required BuildContext context,
  required Map<String, dynamic> product,
  required VoidCallback onSuccess,
}) async {
  try {
    // ==========================================================
    // 1. PRODUCT NAME
    // ==========================================================

    final String name =
        product['name']?.toString() ?? 'Product';


    // ==========================================================
    // 2. PRODUCT PRICE
    // ==========================================================
    //
    // Handles:
    //
    // 10000
    // "10000"
    // "10000.00"
    //
    // ==========================================================

    final dynamic rawPrice = product['price'];

    final double catalogPrice =
        double.tryParse(
          rawPrice?.toString() ?? '0',
        ) ??
        0.0;


    // ==========================================================
    // 3. PRODUCT ID
    // ==========================================================
    //
    // Handles both:
    //
    // int    -> 12
    // String -> "12"
    //
    // ==========================================================

    final dynamic rawProductId =
        product['id'];

    final int? productId =
        int.tryParse(
          rawProductId?.toString() ?? '',
        );


    // ==========================================================
    // 4. WHOLESALER ID
    // ==========================================================

    final dynamic rawWholesalerId =
        product['wholesaler_id'];

    final int? wholesalerId =
        int.tryParse(
          rawWholesalerId?.toString() ?? '',
        );


    // ==========================================================
    // 5. VALIDATE PRODUCT ID
    // ==========================================================

    if (productId == null) {
      debugPrint(
        'BID ERROR: Invalid product ID: $rawProductId',
      );

      AppSnackbars.error(
        title: 'Bid Failed',
        message: 'Invalid product ID.',
      );

      return;
    }


    // ==========================================================
    // 6. VALIDATE WHOLESALER ID
    // ==========================================================

    if (wholesalerId == null) {
      debugPrint(
        'BID ERROR: Invalid wholesaler ID: $rawWholesalerId',
      );

      AppSnackbars.error(
        title: 'Bid Failed',
        message: 'Invalid wholesaler information.',
      );

      return;
    }


    // ==========================================================
    // 7. VALIDATE PRICE
    // ==========================================================

    if (catalogPrice <= 0) {
      debugPrint(
        'BID ERROR: Invalid catalog price: $rawPrice',
      );

      AppSnackbars.error(
        title: 'Bid Failed',
        message: 'Invalid product price.',
      );

      return;
    }


    // ==========================================================
    // 8. CHECK NEGOTIATION HISTORY
    // ==========================================================

    showLoadingDialog();

    final box = GetStorage();

    final dynamic settingsData =
        box.read('public_settings');

    Map<String, dynamic> publicSettings = {};

    if (settingsData is Map) {
      publicSettings =
          Map<String, dynamic>.from(
        settingsData,
      );
    }


    // ==========================================================
    // MAX NEGOTIATION ROUNDS
    // ==========================================================

    final dynamic rawMaxRounds =
        publicSettings['max_negotiation_rounds'];

    final int maxRounds =
        int.tryParse(
          rawMaxRounds?.toString() ?? '3',
        ) ??
        3;


    List<dynamic> bids = [];


    // ==========================================================
    // FETCH BUYER BIDS
    // ==========================================================

    try {
      bids =
          await BuyerService.fetchBuyerBids();
    } catch (e, stackTrace) {
      debugPrint(
        'FETCH BUYER BIDS ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      // Close loading dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      AppSnackbars.error(
        title: 'Error',
        message:
            'Unable to check your previous bids.',
      );

      return;
    }


    // ==========================================================
    // CLOSE LOADING DIALOG
    // ==========================================================

    if (Get.isDialogOpen == true) {
      Get.back();
    }


    // ==========================================================
    // 9. CHECK PREVIOUS BIDS
    // ==========================================================

    final List<dynamic> productBids =
        bids.where((bid) {
      if (bid is! Map) {
        return false;
      }

      final dynamic bidProductId =
          bid['product_id'];

      final int? parsedBidProductId =
          int.tryParse(
        bidProductId?.toString() ?? '',
      );

      return parsedBidProductId ==
          productId;
    }).toList();


    // ==========================================================
    // 10. NEGOTIATION LIMIT
    // ==========================================================

    if (productBids.length >= maxRounds) {
      AppSnackbars.warning(
        title: 'Negotiation Limit',
        message:
            'You have reached the maximum of '
            '$maxRounds negotiations allowed '
            'for this product.',
      );

      return;
    }


    // ==========================================================
    // 11. TEXT CONTROLLERS
    // ==========================================================

    final TextEditingController priceController =
        TextEditingController(
      text: catalogPrice.toStringAsFixed(0),
    );

    final TextEditingController qtyController =
        TextEditingController(
      text: '1',
    );

    final TextEditingController msgController =
        TextEditingController();


    // ==========================================================
    // 12. FORM KEY
    // ==========================================================

    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>();


    // ==========================================================
    // 13. SHOW BID POPUP
    // ==========================================================

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppTheme.radiusMd,
          ),
        ),

        title: Text(
          'Submit Price Offer\n$name',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),

        content: Form(
          key: formKey,

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ==================================================
                // PRICE
                // ==================================================

                const Text(
                  'Your Proposed Price / Unit *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                TextFormField(
                  controller: priceController,

                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  decoration:
                      const InputDecoration(
                    hintText:
                        'Proposed Price',
                    prefixText: 'Rs ',
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Price is required';
                    }

                    final double? price =
                        double.tryParse(
                      value.trim(),
                    );

                    if (price == null ||
                        price <= 0) {
                      return 'Enter a valid price';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),


                // ==================================================
                // QUANTITY
                // ==================================================

                const Text(
                  'Quantity (Lot size) *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                TextFormField(
                  controller: qtyController,

                  keyboardType:
                      TextInputType.number,

                  decoration:
                      const InputDecoration(
                    hintText:
                        'e.g. 50, 100',
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Quantity is required';
                    }

                    final int? quantity =
                        int.tryParse(
                      value.trim(),
                    );

                    if (quantity == null ||
                        quantity <= 0) {
                      return 'Enter a valid quantity';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),


                // ==================================================
                // MESSAGE
                // ==================================================

                const Text(
                  'Additional Message',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                TextFormField(
                  controller: msgController,

                  decoration:
                      const InputDecoration(
                    hintText:
                        'e.g. Proposing deal for quick delivery',
                  ),

                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),


        // ========================================================
        // ACTION BUTTONS
        // ========================================================

        actions: [

          // ======================================================
          // CANCEL
          // ======================================================

          TextButton(
            onPressed: () {
              priceController.dispose();
              qtyController.dispose();
              msgController.dispose();

              Get.back();
            },

            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),


          // ======================================================
          // SUBMIT OFFER
          // ======================================================

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppTheme.primary,

              foregroundColor:
                  Colors.white,

              minimumSize:
                  const Size(100, 42),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  AppTheme.radiusSm,
                ),
              ),
            ),

            onPressed: () async {

              // ==================================================
              // VALIDATE FORM
              // ==================================================

              if (!formKey.currentState!
                  .validate()) {
                return;
              }


              // ==================================================
              // PARSE PRICE
              // ==================================================

              final double? bidPrice =
                  double.tryParse(
                priceController.text.trim(),
              );


              // ==================================================
              // PARSE QUANTITY
              // ==================================================

              final int? quantity =
                  int.tryParse(
                qtyController.text.trim(),
              );


              // ==================================================
              // FINAL VALIDATION
              // ==================================================

              if (bidPrice == null ||
                  bidPrice <= 0) {

                AppSnackbars.error(
                  title: 'Invalid Price',
                  message:
                      'Please enter a valid bid price.',
                );

                return;
              }

              if (quantity == null ||
                  quantity <= 0) {

                AppSnackbars.error(
                  title: 'Invalid Quantity',
                  message:
                      'Please enter a valid quantity.',
                );

                return;
              }


              // ==================================================
              // SAVE MESSAGE BEFORE DISPOSING
              // ==================================================

              final String message =
                  msgController.text.trim();


              // ==================================================
              // CLOSE BID DIALOG
              // ==================================================

              if (Get.isDialogOpen == true) {
                Get.back();
              }


              // ==================================================
              // SHOW LOADING
              // ==================================================

              showLoadingDialog();


              try {

                // =================================================
                // SUBMIT BID
                // =================================================

                final result =
                    await BuyerService.submitBid(

                  productId:
                      productId,

                  productName:
                      name,

                  originalPrice:
                      catalogPrice,

                  quantity:
                      quantity,

                  bidPrice:
                      bidPrice,

                  wholesalerId:
                      wholesalerId,

                  message:
                      message,
                );


                // =================================================
                // CLOSE LOADING
                // =================================================

                if (Get.isDialogOpen == true) {
                  Get.back();
                }


                // =================================================
                // SUCCESS
                // =================================================

                if (result['success'] == true) {

                  AppSnackbars.success(
                    title:
                        'Bid Submitted',

                    message:
                        'Your wholesale price offer '
                        'has been sent to the seller.',
                  );


                  // ===============================================
                  // CALLBACK
                  // ===============================================

                  onSuccess();

                } else {

                  // ===============================================
                  // API FAILURE
                  // ===============================================

                  AppSnackbars.error(
                    title:
                        'Bid Failed',

                    message:
                        result['message']
                                ?.toString() ??
                            'Could not submit bid.',
                  );
                }

              } catch (e, stackTrace) {

                // =================================================
                // API / RUNTIME ERROR
                // =================================================

                debugPrint(
                  'SUBMIT BID ERROR: $e',
                );

                debugPrint(
                  '$stackTrace',
                );


                // =================================================
                // CLOSE LOADER
                // =================================================

                if (Get.isDialogOpen == true) {
                  Get.back();
                }


                AppSnackbars.error(
                  title:
                      'Bid Failed',

                  message:
                      'Something went wrong while '
                      'submitting your bid.',
                );
              }


              // ==================================================
              // DISPOSE CONTROLLERS
              // ==================================================

              priceController.dispose();
              qtyController.dispose();
              msgController.dispose();
            },

            child: const Text(
              'Submit Offer',
            ),
          ),
        ],
      ),

      // User must explicitly Cancel/Submit
      barrierDismissible: false,
    );

  } catch (e, stackTrace) {

    // ==========================================================
    // GLOBAL BID DIALOG ERROR HANDLER
    // ==========================================================

    debugPrint(
      'SHOW BID DIALOG ERROR: $e',
    );

    debugPrint(
      '$stackTrace',
    );


    // ==========================================================
    // CLOSE ANY OPEN DIALOG
    // ==========================================================

    if (Get.isDialogOpen == true) {
      Get.back();
    }


    // ==========================================================
    // SHOW ERROR
    // ==========================================================

    AppSnackbars.error(
      title: 'Bid Error',
      message:
          'Unable to open the bid form. Please try again.',
    );
  }
}