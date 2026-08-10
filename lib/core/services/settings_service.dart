<<<<<<< HEAD
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class SettingsService {
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:3000";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:3000";
    } catch (_) {}
    return "http://localhost:3000";
  }

  static final _box = GetStorage();

  static String? get _token => _box.read('token');

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ""}',
      };

  /// Fetch public settings (accessible by anyone)
  static Future<Map<String, dynamic>> fetchPublicSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/public'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Map<String, String>.from(data['data'])};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load public settings'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Fetch all platform-wide settings (admin only)
  static Future<Map<String, dynamic>> fetchSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Map<String, String>.from(data['data'])};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load settings'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Save platform-wide settings (admin only)
  static Future<Map<String, dynamic>> saveSystemSettings(Map<String, String> settings) async {
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
      return {'success': false, 'message': data['message'] ?? 'Failed to save settings'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Update current user's profile (name, phone, gender)
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
        // Update local storage with fresh user data
        if (data['user'] != null) {
          _box.write('user', data['user']);
        }
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update profile'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Change password for current user
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
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to change password'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }
=======
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class SettingsService {
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:3000";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:3000";
    } catch (_) {}
    return "http://localhost:3000";
  }

  static final _box = GetStorage();

  static String? get _token => _box.read('token');

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ""}',
      };

  /// Fetch public settings (accessible by anyone)
  static Future<Map<String, dynamic>> fetchPublicSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/public'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Map<String, String>.from(data['data'])};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load public settings'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Fetch all platform-wide settings (admin only)
  static Future<Map<String, dynamic>> fetchSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Map<String, String>.from(data['data'])};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load settings'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Save platform-wide settings (admin only)
  static Future<Map<String, dynamic>> saveSystemSettings(Map<String, String> settings) async {
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
      return {'success': false, 'message': data['message'] ?? 'Failed to save settings'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Update current user's profile (name, phone, gender)
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
        // Update local storage with fresh user data
        if (data['user'] != null) {
          _box.write('user', data['user']);
        }
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update profile'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  /// Change password for current user
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
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to change password'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }
>>>>>>> 71b2d73 (change setting file)
}