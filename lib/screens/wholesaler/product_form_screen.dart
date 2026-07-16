import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/snackbars.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _origPriceController = TextEditingController();
  final _qtyController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoadingCategories = true;
  bool _isEditMode = false;
  int? _productId;

  // Product image
  Uint8List? _imageBytes;
  String? _existingImageBase64; // from edit mode args
  final ImagePicker _picker = ImagePicker();

  // Admin override fields
  bool _isAdmin = false;
  List<dynamic> _wholesalers = [];
  dynamic _selectedWholesaler;
  bool _isLoadingWholesalers = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndProduct();
  }

  Future<void> _loadCategoriesAndProduct() async {
    // Check user role
    final box = GetStorage();
    final String role = box.read('role') ?? 'wholesaler';
    if (role.toLowerCase() == 'admin') {
      _isAdmin = true;
      _loadWholesalers();
    }

    // 1. Fetch categories
    try {
      final fetched = await ProductService.fetchCategories();
      final List<String> names = fetched.map((c) => (c['name'] as String)).toList();
      setState(() {
        _categories = names;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print("Error loading categories in form: $e");
      setState(() => _isLoadingCategories = false);
    }

    // 2. Check if in edit mode (arguments passed)
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        _isEditMode = true;
        _productId = args['id'];
        _nameController.text = args['name'] ?? '';
        _descController.text = args['description'] ?? '';
        _priceController.text = (args['price'] ?? '').toString();
        _origPriceController.text = (args['original_price'] ?? '').toString();
        _qtyController.text = (args['quantity'] ?? '1').toString();
        _existingImageBase64 = args['product_image'];

        final String? productCategory = args['category'];
        if (productCategory != null) {
          if (_categories.contains(productCategory)) {
            _selectedCategory = productCategory;
          } else if (productCategory.isNotEmpty) {
            _categories.add(productCategory);
            _selectedCategory = productCategory;
          }
        }
      });
    }
  }

  Future<void> _loadWholesalers() async {
    setState(() => _isLoadingWholesalers = true);
    try {
      final list = await ProductService.fetchApprovedWholesalers();
      setState(() {
        _wholesalers = list;
        _isLoadingWholesalers = false;

        final args = Get.arguments;
        if (args != null && args is Map<String, dynamic>) {
          final int? wsId = args['wholesaler_id'];
          if (wsId != null) {
            _selectedWholesaler = _wholesalers.firstWhere(
              (w) => w['id'] == wsId,
              orElse: () => null,
            );
          }
        }
      });
    } catch (e) {
      print("Error loading approved wholesalers: $e");
      setState(() => _isLoadingWholesalers = false);
    }
  }

  Future<void> _pickImage() async {
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
            const Text('Upload Product Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Optional – helps buyers recognise your product', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.primary, child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() { _imageBytes = bytes; _existingImageBase64 = null; });
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF546E7A), child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 20)),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from photos'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() { _imageBytes = bytes; _existingImageBase64 = null; });
                }
              },
            ),
            if (_imageBytes != null || _existingImageBase64 != null)
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20)),
                title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() { _imageBytes = null; _existingImageBase64 = null; });
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String? _getImageBase64() {
    if (_imageBytes != null) {
      return base64Encode(_imageBytes!);
    }
    return _existingImageBase64;
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      AppSnackbars.warning(title: "Validation Error", message: "Please select a product category.");
      return;
    }

    if (_isAdmin && _selectedWholesaler == null) {
      AppSnackbars.warning(title: "Validation Error", message: "Please select a wholesaler on whose behalf you are publishing.");
      return;
    }

    setState(() => _isSubmitting = true);

    final double price = double.parse(_priceController.text.trim());
    final double origPrice = _origPriceController.text.trim().isNotEmpty
        ? double.parse(_origPriceController.text.trim())
        : price;
    final int qty = _qtyController.text.trim().isNotEmpty
        ? int.parse(_qtyController.text.trim())
        : 1;

    final Map<String, dynamic> productMap = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price': price,
      'original_price': origPrice,
      'quantity': qty,
      'category': _selectedCategory,
      'product_image': _getImageBase64(),
    };

    if (_isAdmin && _selectedWholesaler != null) {
      productMap['wholesaler_id'] = _selectedWholesaler['id'];
      productMap['wholesaler_name'] = _selectedWholesaler['name'];
    }

    Map<String, dynamic> result;
    try {
      if (_isEditMode && _productId != null) {
        result = await ProductService.updateProduct(_productId!, productMap);
      } else {
        result = await ProductService.publishProduct(productMap);
      }
    } catch (e) {
      result = {'success': false, 'message': 'Connection error: $e'};
    }

    setState(() => _isSubmitting = false);

    if (result['success']) {
      Navigator.pop(context, true);
      AppSnackbars.success(
        title: _isEditMode ? "Product Updated" : "Product Published",
        message: result['message'] ?? "Catalog updated successfully.",
      );
    } else {
      AppSnackbars.error(
        title: _isEditMode ? "Update Failed" : "Publish Failed",
        message: result['message'] ?? "An error occurred.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primary;
    final hasImage = _imageBytes != null || (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          _isEditMode ? 'Edit Product Details' : (_isAdmin ? 'Publish on Behalf' : 'Publish Product'),
        ),
      ),
      body: SafeArea(
        child: _isLoadingCategories
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? 'Modify Product Listing' : (_isAdmin ? 'Publish on Behalf of Wholesaler' : 'List a New Product'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditMode
                            ? 'Modify product details.'
                            : (_isAdmin
                                ? 'Select a verified wholesaler and fill out details.'
                                : 'Provide accurate details about your product for clients.'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // ─── Product Image (OPTIONAL) ───────────────────────────
                      const Text('Product Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Optional – helps buyers identify your product', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F6),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: hasImage ? AppTheme.primary : Colors.grey.shade300,
                              width: hasImage ? 1.5 : 1,
                            ),
                          ),
                          child: hasImage
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1),
                                      child: _imageBytes != null
                                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                          : Image.memory(
                                              base64Decode(_existingImageBase64!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
                                            ),
                                    ),
                                    Positioned(
                                      top: 8, right: 8,
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.black54,
                                        child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0, left: 0, right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusMd - 1)),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: const Text('Tap to change or remove', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 40),
                                    SizedBox(height: 10),
                                    Text('Tap to add product image', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                                    SizedBox(height: 4),
                                    Text('Camera or Gallery • Optional', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ─── Wholesaler selection (Admin only) ──────────────────
                      if (_isAdmin) ...[
                        const Text('Wholesaler *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        _isLoadingWholesalers
                            ? const LinearProgressIndicator(color: AppTheme.primary)
                            : DropdownButtonFormField<dynamic>(
                                initialValue: _selectedWholesaler,
                                items: _wholesalers.map((w) {
                                  return DropdownMenuItem<dynamic>(
                                    value: w,
                                    child: Text("${w['name']} (${w['email']})"),
                                  );
                                }).toList(),
                                onChanged: _isEditMode ? null : (val) => setState(() => _selectedWholesaler = val),
                                decoration: const InputDecoration(hintText: 'Select Wholesaler'),
                                validator: (val) => val == null ? 'Please select a wholesaler' : null,
                              ),
                        const SizedBox(height: 18),
                      ],

                      // ─── Product Title ──────────────────────────────────────
                      const Text('Product Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'e.g. Leather Jacket, Sports Shoes'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Product title is required' : null,
                      ),
                      const SizedBox(height: 18),

                      // ─── Category Dropdown ──────────────────────────────────
                      const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        items: _categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        decoration: const InputDecoration(hintText: 'Select category'),
                        validator: (val) => val == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 18),

                      // ─── Price and Original Price ───────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Wholesale Price *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Rs. Price'),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid price';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Original Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _origPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Rs. (Optional)'),
                                  validator: (val) {
                                    if (val != null && val.trim().isNotEmpty) {
                                      if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid price';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ─── Stock Quantity ─────────────────────────────────────
                      const Text('Initial Stock Quantity *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 100'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Quantity is required';
                          if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Invalid quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // ─── Description ────────────────────────────────────────
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(hintText: 'Enter details about sizes, minimum order qty, etc.'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 32),

                      // ─── Submit Button ──────────────────────────────────────
                      _isSubmitting
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: CircularProgressIndicator(color: primaryColor),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd))),
                                onPressed: _submitForm,
                                child: Text(
                                  _isEditMode ? 'Update Listing' : (_isAdmin ? 'Publish Product' : 'Publish Product Listing'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

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