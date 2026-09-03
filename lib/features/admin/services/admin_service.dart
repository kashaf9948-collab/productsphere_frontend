import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class AdminService {
  static String get baseUrl {
    if (kIsWeb) return "http://b2b.sandbox.pk";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:3000";
    } catch (_) {}
    return "http://b2b.sandbox.pk";
  }

  static final box = GetStorage();
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${box.read('token') ?? ""}',
  };

  // Fetch Pending Wholesalers
  static Future<List<dynamic>> fetchPendingWholesalers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pending-wholesalers'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Update Wholesaler Status (Approve/Reject)
  static Future<Map<String, dynamic>> updateBusinessStatus(
    int userId,
    String status,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/update-status'),
        headers: _headers,
        body: json.encode({'userId': userId, 'status': status}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update status',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Delete Product from Catalog (Admin)
  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products/$productId'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete product',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Update Product Status (Approve/Flag)
  static Future<Map<String, dynamic>> updateProductStatus(
    int productId,
    String status,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products/status'),
        headers: _headers,
        body: json.encode({'productId': productId, 'status': status}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update product status',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Create Category
  static Future<Map<String, dynamic>> createCategory(
    String name,
    String? description,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: json.encode({'name': name, 'description': description}),
      );
      final data = json.decode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to create category',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Update Category
  static Future<Map<String, dynamic>> updateCategory(
    int id,
    String name,
    String? description,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
        body: json.encode({'name': name, 'description': description}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update category',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Delete Category
  static Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete category',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Fetch All Bids for Admin
  static Future<List<dynamic>> fetchAdminBids() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/negotiations'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch All Buyers for Admin
  static Future<List<dynamic>> fetchAdminBuyers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/buyers'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch All Orders for Admin
  static Future<List<dynamic>> fetchAdminOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/orders'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch System Settings
  static Future<Map<String, dynamic>> fetchSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': Map<String, String>.from(data['data']),
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to load settings',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  // Save System Settings
  static Future<Map<String, dynamic>> saveSystemSettings(
    Map<String, String> settings,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
        body: json.encode(settings),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to save settings',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  // Fetch All Notifications Audit for Admin
  static Future<List<dynamic>> fetchAdminNotificationsAudit() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/admin'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
