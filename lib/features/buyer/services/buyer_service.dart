import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class BuyerService {
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

  // Fetch Wholesale Products
  static Future<List<dynamic>> fetchWholesaleProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return data['data'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch Categories
 static Future<List<dynamic>> fetchCategories() async {
  try {
    final url = Uri.parse('$baseUrl/categories');

    print('Fetching categories from: $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print('Categories status: ${response.statusCode}');
    print('Categories response: ${response.body}');

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? [];
    }

    print('Categories API error: ${data['message']}');
    return [];
  } catch (e) {
    print('FETCH CATEGORIES ERROR: $e');
    return [];
  }
}
  // Fetch Approved Wholesalers
  static Future<List<dynamic>> fetchApprovedWholesalers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/wholesalers'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return data['data'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  // Place Order (Checkout)
  static Future<Map<String, dynamic>> checkout({
    required String shippingAddress,
    required String phone,
    required String paymentMethod,
    required List<dynamic> items,
    required double totalAmount,
    String? paymentProof,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
        body: json.encode({
          'shipping_address': shippingAddress,
          'phone': phone,
          'payment_method': paymentMethod,
          'items': items,
          'total_amount': totalAmount,
          'payment_proof': paymentProof,
        }),
      );
      final data = json.decode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'orderId': data['orderId'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to place order.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Fetch Buyer Orders
  static Future<List<dynamic>> fetchBuyerOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return data['data'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  // Submit Bid for Negotiation
  static Future<Map<String, dynamic>> submitBid({
    required int productId,
    required String productName,
    required double originalPrice,
    required int quantity,
    required double bidPrice,
    required int wholesalerId,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/negotiations'),
        headers: _headers,
        body: json.encode({
          'product_id': productId,
          'product_name': productName,
          'price': originalPrice,
          'quantity': quantity,
          'bid_price': bidPrice,
          'wholesaler_id': wholesalerId,
          'message': message,
        }),
      );
      final data = json.decode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'bidId': data['bidId'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to submit bid.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Fetch Buyer Bids
  static Future<List<dynamic>> fetchBuyerBids() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/negotiations/buyer'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return data['data'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  // Update Profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? gender,
  }) async {
    try {
      final body = <String, String>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (gender != null) body['gender'] = gender;

      final response = await http.put(
        Uri.parse('$baseUrl/settings/profile'),
        headers: _headers,
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (data['user'] != null) box.write('user', data['user']);
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update profile',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  // Change Password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings/profile'),
        headers: _headers,
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return {'success': true, 'message': data['message']};
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to change password',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  // Fetch Public Settings
  static Future<Map<String, dynamic>> fetchPublicSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/public'),
        headers: {'Content-Type': 'application/json'},
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
        'message': data['message'] ?? 'Failed to load public settings',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  // Fetch User Notifications
  static Future<List<dynamic>> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return data['data'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  // Mark Notification as Read
  static Future<bool> markNotificationAsRead(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/read'),
        headers: _headers,
        body: json.encode({'id': id}),
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
