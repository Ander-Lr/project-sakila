import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'admin_page.dart';
import 'customer_page.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://localhost:8080/api/auth/verify');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': _codeController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _processSuccessfulVerification(response.body);
      } else {
        // Puede ser 400 por código inválido
        String errorMessage = 'Error al verificar el código.';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) {
            errorMessage = data['message'];
          } else if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error de conexión: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://localhost:8080/api/auth/resend-verification');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar('Código reenviado a tu correo.', isError: false);
      } else {
        _showSnackBar('Error al reenviar el código.', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error de conexión: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processSuccessfulVerification(String responseBody) async {
    String jwt = '';
    try {
      final responseData = jsonDecode(responseBody);
      jwt = responseData['token'] ?? responseData['jwt'] ?? '';
    } catch (e) {
      jwt = responseBody;
    }

    if (jwt.isNotEmpty) {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'jwt_token', value: jwt);

      Map<String, dynamic> decodedToken = JwtDecoder.decode(jwt);
      String role = decodedToken['rol'] ?? decodedToken['role'] ?? 'CUSTOMER';
      role = role.toString().toUpperCase();
      await storage.write(key: 'user_role', value: role);

      if (mounted) {
        if (role == 'ADMIN') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => CustomerPage(role: role)),
            (route) => false,
          );
        }
      }
    } else {
      _showSnackBar('Error: El token recibido está vacío.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación de Cuenta')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_unread, size: 80, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 20),
                      const Text(
                        'Revisa tu correo',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hemos enviado un código de verificación a:\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Código de Verificación',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el código';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Verificar', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isLoading ? null : _resendCode,
                        child: const Text('¿No recibiste el código? Reenviar'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
