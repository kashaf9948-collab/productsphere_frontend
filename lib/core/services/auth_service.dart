import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class AuthService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    }
    try {
      if (Platform.isAndroid) {
        return "http://10.0.2.2:3000";
      }
    } catch (_) {}
    return "http://localhost:3000";
  }

  static final box = GetStorage();

  // User Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);
      print('Login API Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        // Save Auth States
        if (data['token'] != null) {
          box.write('token', data['token']);
          box.write('user', data['user']);
          box.write('role', data['user']['role']); // admin, buyer, wholesaler
          box.write('userName', data['user']['name']);
          box.write('isLoggedIn', true);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // User Signup
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String gender,
    String? licenseNo,
    String? businessAddress,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'role': role.toLowerCase(),
        'phone': phone,
        'gender': gender.toLowerCase(),
        'license_no': licenseNo,
        'business_address': businessAddress,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      print('Register API Response: $data');

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Signup successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Signup failed'};
      }
    } catch (e) {
      print('Register error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Fetch Pending Wholesalers
  static Future<List<dynamic>> fetchPendingWholesalers() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pending-wholesalers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Pending Wholesalers Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load pending businesses: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Pending error: $e');
      return [];
    }
  }

  // Update Wholesaler status (approve/reject)
  static Future<Map<String, dynamic>> updateBusinessStatus(int userId, String status) async {
    try {
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/admin/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'status': status,
        }),
      );

      final data = json.decode(response.body);
      print('Update status Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update status'};
      }
    } catch (e) {
      print('Update status error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Fetch all wholesale products
  static Future<List<dynamic>> fetchWholesaleProducts() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Products Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load products: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Products error: $e');
      return [];
    }
  }

  // Delete product from catalog
  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final token = box.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Delete Product Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete product'};
      }
    } catch (e) {
      print('Delete Product error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Update product status (approve/flag)
  static Future<Map<String, dynamic>> updateProductStatus(int productId, String status) async {
    try {
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': productId,
          'status': status,
        }),
      );

      final data = json.decode(response.body);
      print('Update product status Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update product status'};
      }
    } catch (e) {
      print('Update product status error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // FETCH ALL CATEGORIES (PUBLIC)
  static Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);
      print('Fetch Categories Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load categories: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Categories error: $e');
      return [];
    }
  }

  // CREATE CATEGORY (ADMIN ONLY)
  static Future<Map<String, dynamic>> createCategory(String name, String? description) async {
    try {
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      final data = json.decode(response.body);
      print('Create Category Response: $data');

      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create category'};
      }
    } catch (e) {
      print('Create Category error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // UPDATE CATEGORY (ADMIN ONLY)
  static Future<Map<String, dynamic>> updateCategory(int id, String name, String? description) async {
    try {
      final token = box.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      final data = json.decode(response.body);
      print('Update Category Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update category'};
      }
    } catch (e) {
      print('Update Category error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // DELETE CATEGORY (ADMIN ONLY)
  static Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final token = box.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Delete Category Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete category'};
      }
    } catch (e) {
      print('Delete Category error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // FETCH WHOLESALER SPECIFIC PRODUCTS (WHOLESALER ONLY)
  static Future<List<dynamic>> fetchWholesalerProducts(int wholesalerId) async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/products/wholesaler/$wholesalerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Wholesaler Products Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load wholesaler products: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Wholesaler Products error: $e');
      return [];
    }
  }

  // PUBLISH NEW PRODUCT (WHOLESALER ONLY)
  static Future<Map<String, dynamic>> publishProduct(Map<String, dynamic> productMap) async {
    try {
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(productMap),
      );

      final data = json.decode(response.body);
      print('Publish Product Response: $data');

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to publish product'};
      }
    } catch (e) {
      print('Publish Product error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // UPDATE PRODUCT DETAILS (WHOLESALER ONLY)
  static Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> productMap) async {
    try {
      final token = box.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(productMap),
      );

      final data = json.decode(response.body);
      print('Update Product Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update product'};
      }
    } catch (e) {
      print('Update Product error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // DELETE PRODUCT (WHOLESALER ONLY)
  static Future<Map<String, dynamic>> deleteWholesalerProduct(int id) async {
    try {
      final token = box.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Delete Wholesaler Product Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete product'};
      }
    } catch (e) {
      print('Delete Wholesaler Product error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // FETCH ALL APPROVED WHOLESALERS (ADMIN ONLY)
  static Future<List<dynamic>> fetchApprovedWholesalers() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/wholesalers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Approved Wholesalers Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load approved wholesalers: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Approved Wholesalers error: $e');
      return [];
    }
  }

  // Logout
  static void logout() {
    box.remove('token');
    box.remove('user');
    box.remove('role');
    box.remove('userName');
    box.remove('isLoggedIn');
  }
}

