import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  String? _token;
  String? _fullName;
  String? _email;
  String? _role;

  bool get isAuthenticated => _isAuthenticated;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get role => _role;

  AuthProvider();

  Future<void> init() async {
    await _loadSession();
  }

  Future<void> _loadSession() async {
    _token = await _storage.read(key: 'jwt_token');
    if (_token != null && !JwtDecoder.isExpired(_token!)) {
      _parseToken(_token!);
    } else {
      await logout();
    }
    notifyListeners();
  }

  void _parseToken(String token) {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    _fullName = decodedToken['fullName'] ?? 'Usuario';
    _email = decodedToken['email'] ?? '';
    _role = decodedToken['role'] ?? 'CUSTOMER';
    _isAuthenticated = true;
  }

  Future<void> login(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
    _token = token;
    _parseToken(token);
    notifyListeners();
  }

  Future<void> logout() async {
    // Attempt backend logout gracefully (ignoring errors if offline)
    try {
      await AuthService.logout();
    } catch (_) {}
    
    await _storage.deleteAll();
    _isAuthenticated = false;
    _token = null;
    _fullName = null;
    _email = null;
    _role = null;
    notifyListeners();
  }
}
