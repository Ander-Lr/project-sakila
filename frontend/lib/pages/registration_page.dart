import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'verification_page.dart';
import '../services/google_auth_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  StreamSubscription<GoogleSignInAccount?>? _googleAuthSubscription;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerLocal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://localhost:8080/api/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
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
              SnackBar(content: Text(message ?? 'Revisa tu correo para verificar tu cuenta.'), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationPage(email: _emailController.text.trim()),
              ),
            );
          }
        } else {
          await _processSuccessfulLogin(response.body);
        }
      } else if (response.statusCode == 409) {
        _showErrorSnackBar('Este correo ya está registrado.');
      } else if (response.statusCode == 400) {
        // Podríamos intentar parsear los errores específicos del body si Spring Boot los manda,
        // pero mostramos un error general de validación como mínimo.
        _showErrorSnackBar('Error de validación: Revisa los datos ingresados.');
      } else {
        _showErrorSnackBar('Error en el registro: ${response.statusCode}');
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
        _showErrorSnackBar('Token inválido o no autorizado por el servidor (401).');
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

      const storage = FlutterSecureStorage();
      await storage.write(key: 'jwt_token', value: jwt);
      
      Map<String, dynamic> decodedToken = JwtDecoder.decode(jwt);
      String role = decodedToken['rol'] ?? decodedToken['role'] ?? 'CUSTOMER';
      role = role.toString().toUpperCase();
      await storage.write(key: 'user_role', value: role);

      if (mounted) {
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
        title: const Text('Crea Tu Cuenta'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: null, // Minimalist style
                    suffixIcon: Icon(Icons.check_circle, color: Colors.green),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre completo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu correo';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
                    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerLocal,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 20),
                const Text(
                  'O regístrate con',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                _buildGoogleSignInButton(),
                
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes una cuenta? ', style: TextStyle(color: Colors.black54)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Vuelve al login
                      },
                      child: const Text(
                        'Iniciar',
                        style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
