import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/admin_page.dart';
import '../pages/customer_page.dart';
import '../pages/admin_films_page.dart';
import '../pages/admin_rentals_page.dart';
import '../pages/admin_audit_logs_page.dart';
import '../pages/my_rentals_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.role?.toUpperCase() ?? 'CUSTOMER';
    final isAdmin = role == 'ADMIN';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.fullName ?? 'Usuario'),
            accountEmail: Text(authProvider.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Theme.of(context).primaryColor),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const AdminPage())),
            ),
            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text('Administrar Películas'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminFilmsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Todos los Alquileres'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminRentalsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Registros de Auditoría'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminAuditLogsPage()));
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Catálogo de Películas'),
              onTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => CustomerPage(role: role))),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Mis Alquileres'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyRentalsPage()));
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
