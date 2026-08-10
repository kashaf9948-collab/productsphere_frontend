import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/product_service.dart';
import '../../core/utils/theme.dart';
import '../../core/widgets/admin_drawer.dart';
import '../../core/widgets/admin_bottom_nav.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/snackbars.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await ProductService.fetchCategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(text: category != null ? category['name'] : '');
    final descController = TextEditingController(text: category != null ? category['description'] : '');
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          category == null ? 'Add New Category' : 'Edit Category',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Clothing, Electronics',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Garments and apparel items',
                ),
                maxLines: 3,
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
              minimumSize: const Size(100, 45),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Get.back(); // close dialog first
                _saveCategory(
                  id: category?['id'],
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory({int? id, required String name, String? description}) async {
    showLoadingDialog(color: AppTheme.primary);

    Map<String, dynamic> result;
    if (id == null) {
      result = await ProductService.createCategory(name, description);
    } else {
      result = await ProductService.updateCategory(id, name, description);
    }

    Get.back(); // close loading dialog

    if (result['success']) {
      AppSnackbars.success(
        title: "Success",
        message: result['message'] ?? "Category updated successfully",
      );
      _fetchCategories();
    } else {
      AppSnackbars.error(
        title: "Failed",
        message: result['message'] ?? "Operation failed",
      );
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showConfirmDialog(
      title: 'Delete Category',
      content: 'Are you sure you want to delete category "$name"? This might affect products linked to it.',
      confirmColor: AppTheme.expired,
    );

    if (!confirm) return;

    showLoadingDialog(color: AppTheme.primary);

    final result = await ProductService.deleteCategory(id);
    Get.back(); // close loading

    if (result['success']) {
      AppSnackbars.success(
        title: "Deleted",
        message: "Category deleted successfully.",
      );
      _fetchCategories();
    } else {
      AppSnackbars.error(
        title: "Delete Failed",
        message: result['message'] ?? "Unable to delete category.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminDrawer(),
      bottomNavigationBar: const AdminBottomNav(activeIndex: -1),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Category Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchCategories,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : _categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No Categories Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click the + button to add a new category.',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final name = category['name'] ?? 'Unnamed';
                      final desc = category['description'] ?? 'No description provided';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryLight,
                            child: Icon(Icons.category_rounded, color: AppTheme.primary),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              desc,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                                onPressed: () => _showCategoryDialog(category: category),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expired),
                                onPressed: () => _deleteCategory(category['id'], name),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}