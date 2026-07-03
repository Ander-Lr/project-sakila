import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../pages/login_page.dart';
import '../services/google_auth_service.dart';
import '../models/api_error.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080'; // Cambia si usas otro puerto/IP
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        return response.body; // In case it's not JSON
      }
    } else {
      try {
        final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
        throw ApiError.fromJson(errorJson);
      } catch (e) {
        if (e is ApiError) rethrow;
        throw ApiError(
          status: response.statusCode,
          message: 'Error inesperado. Código: ${response.statusCode}',
        );
      }
    }
  }

  // --- GENERIC METHODS ---

  static Future<dynamic> get(String endpoint, {bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint, {bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    return _handleResponse(response);
  }

  // --- LEGACY METHODS (kept for backward compatibility) ---
  static Future<bool> makeAuthenticatedRequest(BuildContext context, String endpoint) async {
    try {
      await get(endpoint, auth: true);
      return true;
    } on ApiError catch (e) {
      if (e.status == 401) {
        _forceLogout(context);
        return false;
      }
      _showErrorSnackBar(context, e.message ?? 'Error ${e.status}', _getColorForStatus(e.status));
      return false;
    } catch (e) {
      _showErrorSnackBar(context, 'Error de red.', Colors.red);
      return false;
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      await post('/api/auth/logout', auth: true);
    } catch (_) {
      _showErrorSnackBar(context, 'Sin conexión al servidor: forzando cierre local.', Colors.orange);
    } finally {
      _executeLocalCleanup(context, 'Sesión cerrada exitosamente.', Colors.blue);
    }
  }

  static void _forceLogout(BuildContext context) async {
    _executeLocalCleanup(context, 'Sesión expirada o inválida. Inicia sesión nuevamente.', Colors.red);
  }

  static void _executeLocalCleanup(BuildContext context, String message, Color color) async {
    await _storage.deleteAll();
    try {
      await GoogleAuthService.instance.disconnect();
    } catch (_) {}
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  static Color _getColorForStatus(int? status) {
    if (status == null) return Colors.red;
    if (status >= 400 && status < 500) return Colors.orange;
    return Colors.red;
  }
}
