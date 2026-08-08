import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class ProductService {
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

  // Fetch all wholesale products
  static Future<List<dynamic>> fetchWholesaleProducts() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
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

      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
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

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
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

  // FETCH ALL APPROVED WHOLESALERS (ROLE-AGNOSTIC)
  static Future<List<dynamic>> fetchApprovedWholesalers() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/products/wholesalers'),
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

  // PLACE CHECKOUT ORDER
  static Future<Map<String, dynamic>> checkout({
    required String shippingAddress,
    required String phone,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? paymentProof,
  }) async {
    try {
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/orders/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      print('Checkout Response: $data');

      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
        return {'success': true, 'message': data['message'], 'orderId': data['orderId']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to place order.'};
      }
    } catch (e) {
      print('Checkout error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // FETCH BUYER ORDERS
  static Future<List<dynamic>> fetchBuyerOrders() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Buyer Orders Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load orders: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Buyer Orders error: $e');
      return [];
    }
  }

  // FETCH WHOLESALER ORDERS
  static Future<List<dynamic>> fetchWholesalerOrders() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/orders/wholesaler'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Wholesaler Orders Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load wholesaler orders: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Wholesaler Orders error: $e');
      return [];
    }
  }

  // UPDATE ORDER STATUS (For Wholesalers)
  static Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/orders/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'orderId': orderId,
          'status': status,
        }),
      );

      final data = json.decode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('Update Order Status error: $e');
      return false;
    }
  }

  // SUBMIT BID FOR NEGOTIATION
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
      final token = box.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/negotiations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      print('Submit Bid Response: $data');

      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
        return {'success': true, 'message': data['message'], 'bidId': data['bidId']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to submit bid.'};
      }
    } catch (e) {
      print('Submit Bid error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // FETCH BUYER BIDS
  static Future<List<dynamic>> fetchBuyerBids() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/negotiations/buyer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Buyer Bids Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load buyer bids: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Buyer Bids error: $e');
      return [];
    }
  }

  // FETCH WHOLESALER BIDS
  static Future<List<dynamic>> fetchWholesalerBids() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/negotiations/wholesaler'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Wholesaler Bids Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load wholesaler bids: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Wholesaler Bids error: $e');
      return [];
    }
  }

  // UPDATE BID STATUS (ACCEPT/REJECT)
  static Future<Map<String, dynamic>> updateBidStatus(int bidId, String status) async {
    try {
      final token = box.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/negotiations/$bidId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
        }),
      );

      final data = json.decode(response.body);
      print('Update Bid Status Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update status.'};
      }
    } catch (e) {
      print('Update Bid Status error: $e');
      return {'success': false, 'message': 'Cannot connect to backend: $e'};
    }
  }

  // FETCH ALL BIDS FOR ADMIN
  static Future<List<dynamic>> fetchAdminBids() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/negotiations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Admin Bids Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load admin bids: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Admin Bids error: $e');
      return [];
    }
  }

  // FETCH ALL REGISTERED BUYERS FOR ADMIN
  static Future<List<dynamic>> fetchAdminBuyers() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/buyers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Admin Buyers Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load buyers: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Admin Buyers error: $e');
      return [];
    }
  }

  // FETCH ALL PLATFORM ORDERS FOR ADMIN
  static Future<List<dynamic>> fetchAdminOrders() async {
    try {
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      print('Fetch Admin Orders Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      } else {
        print('Failed to load admin orders: ${data['message']}');
        return [];
      }
    } catch (e) {
      print('Fetch Admin Orders error: $e');
      return [];
    }
  }
}