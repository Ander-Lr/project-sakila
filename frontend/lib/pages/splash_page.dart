import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import 'admin_page.dart';
import 'customer_page.dart';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.init();

    if (authProvider.isAuthenticated) {
      _navigateToRolePage(authProvider.role ?? 'CUSTOMER');
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    }
  }

  void _navigateToRolePage(String role) {
    if (!mounted) return;
    if (role == 'ADMIN') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPage()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CustomerPage(role: role)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
