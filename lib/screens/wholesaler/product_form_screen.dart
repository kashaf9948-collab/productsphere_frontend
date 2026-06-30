import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/theme.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({Key? key}) : super(key: key);

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

  // Admin override fields
  bool _isAdmin = false;
  List<dynamic> _wholesalers = [];
  dynamic _selectedWholesaler;
  bool _isLoadingWholesalers = false;

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
      final fetched = await AuthService.fetchCategories();
      final List<String> names = fetched
          .map((c) => (c['name'] as String))
          .toList();
      
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
        
        final String? productCategory = args['category'];
        if (productCategory != null) {
          // Prevent dropdown assertion error by checking if category exists in list
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
      final list = await AuthService.fetchApprovedWholesalers();
      setState(() {
        _wholesalers = list;
        _isLoadingWholesalers = false;

        // If in edit mode, select the current wholesaler
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      Get.snackbar(
        "Validation Error",
        "Please select a product category.",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_isAdmin && _selectedWholesaler == null) {
      Get.snackbar(
        "Validation Error",
        "Please select a wholesaler on whose behalf you are publishing.",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final primaryColor = _isAdmin ? Colors.purple.shade700 : Colors.indigo.shade700;

    // Show loading
    Get.dialog(
      Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: primaryColor),
          ),
        ),
      ),
      barrierDismissible: false,
    );

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
    };

    if (_isAdmin && _selectedWholesaler != null) {
      productMap['wholesaler_id'] = _selectedWholesaler['id'];
      productMap['wholesaler_name'] = _selectedWholesaler['name'];
    }

    Map<String, dynamic> result;
    if (_isEditMode && _productId != null) {
      result = await AuthService.updateProduct(_productId!, productMap);
    } else {
      result = await AuthService.publishProduct(productMap);
    }

    Get.back(); // Close loading dialog

    if (result['success']) {
      Get.snackbar(
        _isEditMode ? "Product Updated" : "Product Published",
        result['message'] ?? "Catalog updated successfully.",
        backgroundColor: AppTheme.activeLight,
        colorText: AppTheme.active,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Redirect or return back
      Get.back(result: true);
    } else {
      Get.snackbar(
        "Publish Failed",
        result['message'] ?? "An error occurred.",
        backgroundColor: AppTheme.expiredLight,
        colorText: AppTheme.expired,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _isAdmin ? Colors.purple.shade700 : Colors.indigo.shade700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _isEditMode ? 'Edit Product Details' : (_isAdmin ? 'Publish on Behalf' : 'Publish Product'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoadingCategories
            ? Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
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

                      // Wholesaler selection dropdown (Admin only)
                      if (_isAdmin) ...[
                        const Text('Wholesaler *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        _isLoadingWholesalers
                            ? const LinearProgressIndicator(color: Colors.purple)
                            : DropdownButtonFormField<dynamic>(
                                value: _selectedWholesaler,
                                items: _wholesalers.map((w) {
                                  return DropdownMenuItem<dynamic>(
                                    value: w,
                                    child: Text("${w['name']} (${w['email']})"),
                                  );
                                }).toList(),
                                onChanged: _isEditMode ? null : (val) {
                                  setState(() {
                                    _selectedWholesaler = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Select Wholesaler',
                                ),
                                validator: (val) => val == null ? 'Please select a wholesaler' : null,
                              ),
                        const SizedBox(height: 18),
                      ],

                      // Name
                      const Text('Product Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Leather Jacket, Sports Shoes',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Product title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Category Dropdown
                      const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: _categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Select category',
                        ),
                        validator: (val) => val == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 18),

                      // Price and Original Price (Side by Side)
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
                                  decoration: const InputDecoration(
                                    hintText: 'Rs. Price',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(val) == null || double.parse(val) <= 0) {
                                      return 'Invalid price';
                                    }
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
                                  decoration: const InputDecoration(
                                    hintText: 'Rs. (Optional)',
                                  ),
                                  validator: (val) {
                                    if (val != null && val.trim().isNotEmpty) {
                                      if (double.tryParse(val) == null || double.parse(val) <= 0) {
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
                      const SizedBox(height: 18),

                      // Stock/Quantity
                      const Text('Initial Stock Quantity *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 100',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          if (int.tryParse(val) == null || int.parse(val) <= 0) {
                            return 'Invalid quantity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Description
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          hintText: 'Enter details about sizes, minimum order qty, etc.',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        onPressed: _submitForm,
                        child: Text(
                          _isEditMode ? 'Update Listing' : (_isAdmin ? 'Publish Product' : 'Publish Product Listing'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
