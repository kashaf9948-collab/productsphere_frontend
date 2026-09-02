import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class WholesalerService {
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

  // Fetch Wholesaler Specific Products
  static Future<List<dynamic>> fetchWholesalerProducts(int wholesalerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/wholesaler/$wholesalerId'),
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

  // Publish New Product
  static Future<Map<String, dynamic>> publishProduct(
    Map<String, dynamic> productMap,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
        body: json.encode(productMap),
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
        'message': data['message'] ?? 'Failed to publish product',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Update Product Details
  static Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> productMap,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
        body: json.encode(productMap),
      );
      final data = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update product',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Delete Wholesaler Product
  static Future<Map<String, dynamic>> deleteWholesalerProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return {'success': true, 'message': data['message']};
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete product',
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // Fetch Wholesaler Orders
  static Future<List<dynamic>> fetchWholesalerOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/wholesaler'),
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

  // Update Order Status
  static Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/update-status'),
        headers: _headers,
        body: json.encode({'orderId': orderId, 'status': status}),
      );
      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Fetch Wholesaler Bids
  static Future<List<dynamic>> fetchWholesalerBids() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/negotiations/wholesaler'),
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

  // Update Bid Status (Accept/Reject)
 static Future<Map<String, dynamic>> updateBidStatus(
    int bidId,
    String status, {
    String? rejectionMessage,
}) async {
  try {
    final body = {
      'status': status,
    };

    if (rejectionMessage != null &&
        rejectionMessage.trim().isNotEmpty) {
      body['rejection_message'] = rejectionMessage.trim();
    }

    final response = await http.put(
      Uri.parse('$baseUrl/negotiations/$bidId/status'),
      headers: _headers,
      body: json.encode(body),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'success': true,
        'message': data['message'],
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Failed to update status.',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Cannot connect to backend: $e',
    };
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
