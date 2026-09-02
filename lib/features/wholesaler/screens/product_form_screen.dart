import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../services/wholesaler_service.dart';
import '../../buyer/services/buyer_service.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/snackbars.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // FORM CONTROLLERS
  // ============================================================

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _origPriceController = TextEditingController();
  final _qtyController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoadingCategories = true;

  // ============================================================
  // EDIT MODE
  // ============================================================

  bool _isEditMode = false;
  int? _productId;

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Uint8List? _imageBytes;

  // Existing image received from backend while editing
  String? _existingImageBase64;

  // Important:
  // This tells us whether the user explicitly removed an
  // existing image.
  bool _imageRemoved = false;

  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // ADMIN
  // ============================================================

  bool _isAdmin = false;
  List<dynamic> _wholesalers = [];
  dynamic _selectedWholesaler;
  bool _isLoadingWholesalers = false;

  // ============================================================
  // SUBMIT
  // ============================================================

  bool _isSubmitting = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndProduct();
  }

  // ============================================================
  // LOAD CATEGORIES + EDIT PRODUCT
  // ============================================================

  Future<void> _loadCategoriesAndProduct() async {
    final box = GetStorage();

    final String role =
        (box.read('role') ?? 'wholesaler').toString();

    if (role.toLowerCase() == 'admin') {
      _isAdmin = true;
      _loadWholesalers();
    }

    // ------------------------------------------------------------
    // LOAD CATEGORIES
    // ------------------------------------------------------------

    try {
      final fetched = await BuyerService.fetchCategories();

      final List<String> names = fetched
          .map<String>(
            (c) => (c['name'] ?? '').toString(),
          )
          .where((name) => name.isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _categories = names;
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint(
        "Error loading categories in form: $e",
      );

      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });
    }

    // ------------------------------------------------------------
    // CHECK EDIT MODE
    // ------------------------------------------------------------

    final args = Get.arguments;

    if (args != null && args is Map<String, dynamic>) {
      final productId = args['id'];

      setState(() {
        _isEditMode = true;

        if (productId is int) {
          _productId = productId;
        } else {
          _productId = int.tryParse(
            productId?.toString() ?? '',
          );
        }

        _nameController.text =
            (args['name'] ?? '').toString();

        _descController.text =
            (args['description'] ?? '').toString();

        _priceController.text =
            (args['price'] ?? '').toString();

        _origPriceController.text =
            (args['original_price'] ?? '').toString();

        _qtyController.text =
            (args['quantity'] ?? '1').toString();

        final existingImage =
            args['product_image'];

        if (existingImage != null &&
            existingImage.toString().isNotEmpty) {
          _existingImageBase64 =
              existingImage.toString();
        } else {
          _existingImageBase64 = null;
        }

        final String? productCategory =
            args['category']?.toString();

        if (productCategory != null &&
            productCategory.isNotEmpty) {
          if (!_categories.contains(productCategory)) {
            _categories.add(productCategory);
          }

          _selectedCategory = productCategory;
        }
      });
    }
  }

  // ============================================================
  // LOAD APPROVED WHOLESALERS
  // ============================================================

  Future<void> _loadWholesalers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingWholesalers = true;
    });

    try {
      final list =
          await BuyerService.fetchApprovedWholesalers();

      if (!mounted) return;

      setState(() {
        _wholesalers = list;
        _isLoadingWholesalers = false;

        final args = Get.arguments;

        if (args != null &&
            args is Map<String, dynamic>) {
          final wsId = args['wholesaler_id'];

          if (wsId != null) {
            final int? parsedId =
                wsId is int
                    ? wsId
                    : int.tryParse(
                        wsId.toString(),
                      );

            if (parsedId != null) {
              for (final wholesaler
                  in _wholesalers) {
                final wholesalerId =
                    wholesaler['id'];

                final int? currentId =
                    wholesalerId is int
                        ? wholesalerId
                        : int.tryParse(
                            wholesalerId
                                .toString(),
                          );

                if (currentId == parsedId) {
                  _selectedWholesaler =
                      wholesaler;
                  break;
                }
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint(
        "Error loading approved wholesalers: $e",
      );

      if (!mounted) return;

      setState(() {
        _isLoadingWholesalers = false;
      });
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Upload Product Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Optional – helps buyers recognise your product',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // CAMERA
            // ==================================================

            ListTile(
              leading: const CircleAvatar(
                backgroundColor:
                    Color.fromRGBO(
                  0,
                  121,
                  107,
                  1,
                ),
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

                try {
                  final picked =
                      await _picker.pickImage(
                    source:
                        ImageSource.camera,

                    // IMPORTANT:
                    // Resize large camera images
                    maxWidth: 800,
                    maxHeight: 800,

                    // Compress image
                    imageQuality: 60,
                  );

                  if (picked != null) {
                    final bytes =
                        await picked.readAsBytes();

                    if (!mounted) return;

                    setState(() {
                      _imageBytes = bytes;

                      // New image selected
                      _existingImageBase64 = null;

                      // User did NOT remove image
                      _imageRemoved = false;
                    });

                    debugPrint(
                      "Selected image size: "
                      "${(bytes.length / 1024).toStringAsFixed(1)} KB",
                    );
                  }
                } catch (e) {
                  debugPrint(
                    "Camera image error: $e",
                  );

                  AppSnackbars.error(
                    title: "Image Error",
                    message:
                        "Unable to select image.",
                  );
                }
              },
            ),

            // ==================================================
            // GALLERY
            // ==================================================

            ListTile(
              leading: const CircleAvatar(
                backgroundColor:
                    Color(0xFF546E7A),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                ),
              ),
              title: const Text(
                'Choose from Gallery',
              ),
              subtitle: const Text(
                'Select from photos',
              ),
              onTap: () async {
                Navigator.pop(ctx);

                try {
                  final picked =
                      await _picker.pickImage(
                    source:
                        ImageSource.gallery,

                    // IMPORTANT:
                    // Resize large gallery images
                    maxWidth: 800,
                    maxHeight: 800,

                    // Compress image
                    imageQuality: 60,
                  );

                  if (picked != null) {
                    final bytes =
                        await picked.readAsBytes();

                    if (!mounted) return;

                    setState(() {
                      _imageBytes = bytes;

                      // New image selected
                      _existingImageBase64 = null;

                      // User did NOT remove image
                      _imageRemoved = false;
                    });

                    debugPrint(
                      "Selected image size: "
                      "${(bytes.length / 1024).toStringAsFixed(1)} KB",
                    );
                  }
                } catch (e) {
                  debugPrint(
                    "Gallery image error: $e",
                  );

                  AppSnackbars.error(
                    title: "Image Error",
                    message:
                        "Unable to select image.",
                  );
                }
              },
            ),

            // ==================================================
            // REMOVE IMAGE
            // ==================================================

            if (_imageBytes != null ||
                _existingImageBase64 != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);

                  setState(() {
                    _imageBytes = null;
                    _existingImageBase64 = null;

                    // Remember that the user
                    // explicitly removed it.
                    _imageRemoved = true;
                  });
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXISTING IMAGE DECODER
  // ============================================================

  Uint8List? _decodeExistingImage() {
    if (_existingImageBase64 == null ||
        _existingImageBase64!.isEmpty) {
      return null;
    }

    try {
      String imageString =
          _existingImageBase64!.trim();

      // Handle data URI:
      // data:image/jpeg;base64,XXXX
      if (imageString.contains(',')) {
        imageString =
            imageString.split(',').last;
      }

      return base64Decode(imageString);
    } catch (e) {
      debugPrint(
        "Existing image decode error: $e",
      );

      return null;
    }
  }

  // ============================================================
  // SUBMIT FORM
  // ============================================================

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    // ------------------------------------------------------------
    // VALIDATION
    // ------------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      AppSnackbars.warning(
        title: "Validation Error",
        message:
            "Please select a product category.",
      );
      return;
    }

    if (_isAdmin &&
        _selectedWholesaler == null) {
      AppSnackbars.warning(
        title: "Validation Error",
        message:
            "Please select a wholesaler on whose behalf you are publishing.",
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ----------------------------------------------------------
      // PRICE
      // ----------------------------------------------------------

      final double price =
          double.parse(
        _priceController.text.trim(),
      );

      // ----------------------------------------------------------
      // ORIGINAL PRICE
      // ----------------------------------------------------------

      final double origPrice =
          _origPriceController
                  .text
                  .trim()
                  .isNotEmpty
              ? double.parse(
                  _origPriceController.text
                      .trim(),
                )
              : price;

      // ----------------------------------------------------------
      // QUANTITY
      // ----------------------------------------------------------

      final int qty =
          _qtyController.text
                  .trim()
                  .isNotEmpty
              ? int.parse(
                  _qtyController.text.trim(),
                )
              : 1;

      // ----------------------------------------------------------
      // PRODUCT DATA
      // ----------------------------------------------------------

      final Map<String, dynamic>
          productMap = {
        'name':
            _nameController.text.trim(),

        'description':
            _descController.text.trim(),

        'price': price,

        'original_price':
            origPrice,

        'quantity': qty,

        'category':
            _selectedCategory,
      };

      // ==========================================================
      // IMAGE HANDLING
      // ==========================================================

      if (_imageBytes != null) {
        // NEW IMAGE
        //
        // Only the newly selected/compressed
        // image is sent.
        final String imageBase64 =
            base64Encode(_imageBytes!);

        productMap['product_image'] =
            imageBase64;

        debugPrint(
          "Uploading NEW image: "
          "${(_imageBytes!.length / 1024).toStringAsFixed(1)} KB",
        );
      } else if (_isEditMode &&
          _imageRemoved) {
        // USER REMOVED EXISTING IMAGE
        //
        // Tell backend to remove it.
        productMap['product_image'] =
            null;

        debugPrint(
          "Existing image removed.",
        );
      } else {
        // IMPORTANT:
        //
        // Edit mode + user did not change
        // image = DON'T SEND IMAGE.
        //
        // This prevents the old large Base64
        // image from being uploaded again.
        debugPrint(
          "Image unchanged. "
          "Not sending image.",
        );
      }

      // ==========================================================
      // ADMIN WHOLESALER
      // ==========================================================

      if (_isAdmin &&
          _selectedWholesaler != null) {
        productMap['wholesaler_id'] =
            _selectedWholesaler['id'];

        productMap['wholesaler_name'] =
            _selectedWholesaler['name'];
      }

      // ==========================================================
      // DEBUG PAYLOAD SIZE
      // ==========================================================

      try {
        final encodedPayload =
            jsonEncode(productMap);

        debugPrint(
          "Total request payload: "
          "${(encodedPayload.length / 1024).toStringAsFixed(1)} KB",
        );
      } catch (e) {
        debugPrint(
          "Payload size calculation error: $e",
        );
      }

      // ==========================================================
      // API REQUEST
      // ==========================================================

      Map<String, dynamic> result;

      if (_isEditMode &&
          _productId != null) {
        result =
            await WholesalerService
                .updateProduct(
          _productId!,
          productMap,
        );
      } else {
        result =
            await WholesalerService
                .publishProduct(
          productMap,
        );
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // ==========================================================
      // SUCCESS
      // ==========================================================

      if (result['success'] == true) {
        Navigator.pop(context, true);

        AppSnackbars.success(
          title: _isEditMode
              ? "Product Updated"
              : "Product Published",
          message:
              result['message'] ??
                  "Catalog updated successfully.",
        );
      }

      // ==========================================================
      // API ERROR
      // ==========================================================

      else {
        AppSnackbars.error(
          title: _isEditMode
              ? "Update Failed"
              : "Publish Failed",
          message:
              result['message'] ??
                  "An error occurred.",
        );
      }
    } catch (e) {
      debugPrint(
        "Product submit error: $e",
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      AppSnackbars.error(
        title: _isEditMode
            ? "Update Failed"
            : "Publish Failed",
        message:
            "Unable to connect to backend: $e",
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        AppTheme.primaryDark;

    final Uint8List? existingImageBytes =
        _decodeExistingImage();

    final bool hasImage =
        _imageBytes != null ||
        existingImageBytes != null;

    return Scaffold(
      backgroundColor:
          AppTheme.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            primaryColor,

        title: Text(
          _isEditMode
              ? 'Edit Product Details'
              : (_isAdmin
                  ? 'Publish on Behalf'
                  : 'Publish Product'),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: _isLoadingCategories
            ? Center(
                child:
                    CircularProgressIndicator(
                  color: primaryColor,
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(20),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      Text(
                        _isEditMode
                            ? 'Modify Product Listing'
                            : (_isAdmin
                                ? 'Publish on Behalf of Wholesaler'
                                : 'List a New Product'),
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _isEditMode
                            ? 'Modify product details.'
                            : (_isAdmin
                                ? 'Select a verified wholesaler and fill out details.'
                                : 'Provide accurate details about your product for clients.'),
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // PRODUCT IMAGE
                      // ==================================================

                      const Text(
                        'Product Image',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Optional – helps buyers identify your product',
                        style:
                            TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: _pickImage,

                        child: Container(
                          width:
                              double.infinity,
                          height: 160,

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
                              color: hasImage
                                  ? AppTheme
                                      .primary
                                  : Colors
                                      .grey
                                      .shade300,
                              width: hasImage
                                  ? 1.5
                                  : 1,
                            ),
                          ),

                          child: hasImage
                              ? Stack(
                                  fit: StackFit
                                      .expand,

                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                        AppTheme
                                                .radiusMd -
                                            1,
                                      ),

                                      child:
                                          _imageBytes !=
                                                  null
                                              ? Image.memory(
                                                  _imageBytes!,
                                                  fit: BoxFit
                                                      .cover,
                                                )
                                              : existingImageBytes !=
                                                      null
                                                  ? Image.memory(
                                                      existingImageBytes,
                                                      fit: BoxFit
                                                          .cover,
                                                      errorBuilder:
                                                          (
                                                        _,
                                                        __,
                                                        ___,
                                                      ) {
                                                        return const Center(
                                                          child:
                                                              Icon(
                                                            Icons
                                                                .broken_image_rounded,
                                                            size:
                                                                40,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : const Center(
                                                      child:
                                                          Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        size:
                                                            40,
                                                      ),
                                                    ),
                                    ),

                                    // EDIT ICON
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child:
                                          CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            Colors.black54,
                                        child:
                                            const Icon(
                                          Icons
                                              .edit_rounded,
                                          size: 16,
                                          color:
                                              Colors.white,
                                        ),
                                      ),
                                    ),

                                    // BOTTOM TEXT
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,

                                      child:
                                          Container(
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .black
                                              .withValues(
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
                                              8,
                                        ),

                                        child:
                                            const Text(
                                          'Tap to change or remove',
                                          textAlign:
                                              TextAlign
                                                  .center,
                                          style:
                                              TextStyle(
                                            color: Colors
                                                .white,
                                            fontSize:
                                                12,
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
                                      color: AppTheme
                                          .primary,
                                      size: 40,
                                    ),

                                    SizedBox(
                                      height: 10,
                                    ),

                                    Text(
                                      'Tap to add product image',
                                      style:
                                          TextStyle(
                                        color: AppTheme
                                            .textSecondary,
                                        fontSize:
                                            13,
                                        fontWeight:
                                            FontWeight
                                                .w500,
                                      ),
                                    ),

                                    SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      'Camera or Gallery • Optional',
                                      style:
                                          TextStyle(
                                        color: AppTheme
                                            .textHint,
                                        fontSize:
                                            11,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // WHOLESALER
                      // ==================================================

                      if (_isAdmin) ...[
                        const Text(
                          'Wholesaler *',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        _isLoadingWholesalers
                            ? const LinearProgressIndicator(
                                color: AppTheme
                                    .primary,
                              )
                            : DropdownButtonFormField<
                                dynamic>(
                                initialValue:
                                    _selectedWholesaler,

                                items:
                                    _wholesalers
                                        .map(
                                          (w) {
                                            return DropdownMenuItem<
                                                dynamic>(
                                              value:
                                                  w,
                                              child:
                                                  Text(
                                                "${w['name']} (${w['email']})",
                                              ),
                                            );
                                          },
                                        )
                                        .toList(),

                                onChanged:
                                    _isEditMode
                                        ? null
                                        : (val) {
                                            setState(
                                              () =>
                                                  _selectedWholesaler =
                                                      val,
                                            );
                                          },

                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'Select Wholesaler',
                                ),

                                validator:
                                    (val) =>
                                        val ==
                                                null
                                            ? 'Please select a wholesaler'
                                            : null,
                              ),

                        const SizedBox(
                          height: 18,
                        ),
                      ],

                      // ==================================================
                      // PRODUCT TITLE
                      // ==================================================

                      const Text(
                        'Product Title *',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextFormField(
                        controller:
                            _nameController,

                        decoration:
                            const InputDecoration(
                          hintText:
                              'e.g. Leather Jacket, Sports Shoes',
                        ),

                        validator: (val) {
                          if (val ==
                                  null ||
                              val.trim()
                                  .isEmpty) {
                            return 'Product title is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // CATEGORY
                      // ==================================================

                      const Text(
                        'Category *',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            _selectedCategory,

                        items:
                            _categories
                                .map(
                                  (c) =>
                                      DropdownMenuItem<
                                          String>(
                                    value: c,
                                    child:
                                        Text(c),
                                  ),
                                )
                                .toList(),

                        onChanged:
                            (val) {
                          setState(
                            () =>
                                _selectedCategory =
                                    val,
                          );
                        },

                        decoration:
                            const InputDecoration(
                          hintText:
                              'Select category',
                        ),

                        validator: (val) =>
                            val == null
                                ? 'Please select a category'
                                : null,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PRICE
                      // ==================================================

                      Row(
                        children: [
                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                const Text(
                                  'Wholesale Price *',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                TextFormField(
                                  controller:
                                      _priceController,

                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal:
                                        true,
                                  ),

                                  decoration:
                                      const InputDecoration(
                                    hintText:
                                        'Rs. Price',
                                  ),

                                  validator:
                                      (val) {
                                    if (val ==
                                            null ||
                                        val
                                            .trim()
                                            .isEmpty) {
                                      return 'Required';
                                    }

                                    final value =
                                        double.tryParse(
                                      val.trim(),
                                    );

                                    if (value ==
                                            null ||
                                        value <=
                                            0) {
                                      return 'Invalid price';
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                const Text(
                                  'Original Price',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                TextFormField(
                                  controller:
                                      _origPriceController,

                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal:
                                        true,
                                  ),

                                  decoration:
                                      const InputDecoration(
                                    hintText:
                                        'Rs. (Optional)',
                                  ),

                                  validator:
                                      (val) {
                                    if (val !=
                                            null &&
                                        val
                                            .trim()
                                            .isNotEmpty) {
                                      final value =
                                          double.tryParse(
                                        val.trim(),
                                      );

                                      if (value ==
                                              null ||
                                          value <=
                                              0) {
                                        return 'Invalid price';
                                      }
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // QUANTITY
                      // ==================================================

                      const Text(
                        'Initial Stock Quantity *',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextFormField(
                        controller:
                            _qtyController,

                        keyboardType:
                            TextInputType.number,

                        decoration:
                            const InputDecoration(
                          hintText:
                              'e.g. 100',
                        ),

                        validator: (val) {
                          if (val ==
                                  null ||
                              val.trim()
                                  .isEmpty) {
                            return 'Quantity is required';
                          }

                          final value =
                              int.tryParse(
                            val.trim(),
                          );

                          if (value ==
                                  null ||
                              value <= 0) {
                            return 'Invalid quantity';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // DESCRIPTION
                      // ==================================================

                      const Text(
                        'Description',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextFormField(
                        controller:
                            _descController,

                        decoration:
                            const InputDecoration(
                          hintText:
                              'Enter details about sizes, minimum order qty, etc.',
                        ),

                        maxLines: 4,
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      // ==================================================
                      // SUBMIT
                      // ==================================================

                      _isSubmitting
                          ? Center(
                              child:
                                  Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical:
                                      8.0,
                                ),
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      primaryColor,
                                ),
                              ),
                            )
                          : SizedBox(
                              width:
                                  double.infinity,
                              height: 50,

                              child:
                                  ElevatedButton(
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      primaryColor,
                                  elevation:
                                      0,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      AppTheme
                                          .radiusMd,
                                    ),
                                  ),
                                ),

                                onPressed:
                                    _submitForm,

                                child:
                                    Text(
                                  _isEditMode
                                      ? 'Update Listing'
                                      : (_isAdmin
                                          ? 'Publish Product'
                                          : 'Publish Product Listing'),

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        15,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: Colors
                                        .white,
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _origPriceController.dispose();
    _qtyController.dispose();

    super.dispose();
  }
}