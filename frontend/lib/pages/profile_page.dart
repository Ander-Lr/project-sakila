import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';
import '../services/api_service.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfilePage({super.key, required this.userData});

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout(context);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    // JWT dates (iat, exp) are usually in seconds since epoch
    final int seconds = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return date.toLocal().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos extraídos del JWT:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text('ID Usuario: ${userData['sub'] ?? userData['id'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Correo: ${userData['correo'] ?? userData['email'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Nombre: ${userData['nombre'] ?? userData['name'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Rol: ${userData['rol'] ?? userData['role'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Emitido (iat): ${_formatDate(userData['iat'])}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Expira (exp): ${_formatDate(userData['exp'])}', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
