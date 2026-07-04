import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async';
import 'admin_page.dart';
import 'customer_page.dart';
import 'registration_page.dart';
import 'verification_page.dart';
import '../services/google_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _obscurePassword = true;

  StreamSubscription<GoogleSignInAccount?>? _googleAuthSubscription;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Escuchar cambios de Google
    _googleAuthSubscription = GoogleAuthService.instance.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        if (auth.idToken != null) {
          await _sendGoogleTokenToBackend(auth.idToken!);
        } else {
          _showErrorSnackBar('No se pudo obtener el ID Token.');
        }
      }
    });
  }

  @override
  void dispose() {
    _googleAuthSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginLocal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://localhost:8080/api/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _processSuccessfulLogin(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (response.statusCode == 403) {
          String? status;
          String? message;
          try {
            final data = jsonDecode(response.body);
            status = data['status'];
            message = data['message'];
          } catch (_) {}

          if (status == 'PENDING_VERIFICATION') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message ?? 'Debes verificar tu cuenta primero.'), backgroundColor: Colors.orange),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationPage(email: _emailController.text.trim()),
                ),
              );
              return;
            }
          }
        }
        _showErrorSnackBar('Correo o contraseña incorrectos o cuenta no verificada.');
      } else {
        _showErrorSnackBar('Error desconocido: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendGoogleTokenToBackend(String idToken) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://localhost:8080/api/auth/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _processSuccessfulLogin(response.body);
      } else if (response.statusCode == 401) {
        print('Error 401 from Backend: ${response.body}');
        _showErrorSnackBar('Token inválido o no autorizado por el servidor (401). Verifica la terminal de Spring Boot.');
      } else {
        _showErrorSnackBar('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error de red: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      GoogleAuthService.instance.disconnect();
    }
  }

  Future<void> _processSuccessfulLogin(String responseBody) async {
    String jwt = '';
    String? backendMessage;
    try {
      final responseData = jsonDecode(responseBody);
      jwt = responseData['token'] ?? responseData['jwt'] ?? '';
      backendMessage = responseData['message'];
    } catch (e) {
      jwt = responseBody;
    }

    if (backendMessage != null && backendMessage.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(backendMessage), backgroundColor: Colors.green),
      );
    }

    if (jwt.isNotEmpty) {
      print('\n========== JWT GENERADO POR SPRING BOOT ==========');
      print(jwt);
      print('==================================================\n');

      if (mounted) {
        await context.read<AuthProvider>().login(jwt);
        final role = context.read<AuthProvider>().role?.toUpperCase() ?? 'CUSTOMER';
        
        if (role == 'ADMIN') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CustomerPage(role: role)));
        }
      }
    } else {
      _showErrorSnackBar('Error: El token recibido está vacío.');
    }
  }

  Future<void> _handleMobileGoogleSignIn() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await GoogleAuthService.instance.signIn();
    } catch (error) {
      if (mounted) _showErrorSnackBar('Error iniciando sesión: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildGoogleSignInButton() {
    if (kIsWeb) {
      return IgnorePointer(
        ignoring: _isLoading,
        child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton(),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleMobileGoogleSignIn,
        icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg', height: 24),
        label: const Text('Google', style: TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Inicio'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: null, // As per minimalist design
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa tu correo';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                          return null;
                        },
                      ),

                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _loginLocal,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        child: const Text('Iniciar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      
                      const SizedBox(height: 20),
                      const Text(
                        'O continua con',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      _buildGoogleSignInButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
