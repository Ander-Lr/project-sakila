import 'api_service.dart';

class AuthService {
  static Future<dynamic> login(String email, String password) async {
    return await ApiService.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
  }

  static Future<dynamic> register({
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    return await ApiService.post(
      '/api/auth/register',
      body: {
        'email': email,
        'fullName': fullName,
        'password': password,
        'role': role,
      },
      auth: false,
    );
  }

  static Future<dynamic> loginWithGoogle(String idToken) async {
    return await ApiService.post(
      '/api/auth/google',
      body: {'token': idToken},
      auth: false,
    );
  }

  static Future<dynamic> verifyMfa(String email, String code) async {
    return await ApiService.post(
      '/api/auth/verify',
      body: {'email': email, 'code': code},
      auth: false,
    );
  }

  static Future<dynamic> resendCode(String email) async {
    return await ApiService.post(
      '/api/auth/resend-code',
      body: {'email': email},
      auth: false,
    );
  }

  static Future<void> logout() async {
    return await ApiService.post('/api/auth/logout', auth: true);
  }
}
