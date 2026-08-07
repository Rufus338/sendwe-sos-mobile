/// Routeur par rôle après connexion (section 9 — même app, deux rôles).

import 'package:flutter/material.dart';

import '../../core/token_storage.dart';
import '../auth/login_screen.dart';
import '../driver/driver_home_screen.dart';
import '../patient/patient_home_screen.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final role = await TokenStorage.role();
    final token = await TokenStorage.accessToken();
    setState(() {
      _role = role;
      _loading = false;
    });
    if (token == null) {
      // Session invalide → retour login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_role == 'AMBULANCIER') return const DriverHomeScreen();
    if (_role == 'PATIENT') return const PatientHomeScreen();
    // ADMIN_HOSPITAL/SUPER_ADMIN n'utilisent pas l'app mobile
    return const Scaffold(
      body: Center(child: Text('Utilisez le dashboard web')),
    );
  }
}
