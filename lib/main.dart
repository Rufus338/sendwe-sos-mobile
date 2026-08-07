import 'package:flutter/material.dart';

import 'core/notification_service.dart';
import 'core/token_storage.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/role_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise FCM (notifications push — PAS la base de données, qui reste Neon).
  // Ignore les erreurs en dev (Firebase non configuré) pour ne pas bloquer le démarrage.
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // Firebase pas encore configuré (google-services.json manquant en dev)
  }
  runApp(const SendweSosApp());
}

class SendweSosApp extends StatelessWidget {
  const SendweSosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sendwe SOS',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}

/// Écran de démarrage : redirige vers le rôle (si connecté) ou le login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const _AuthGate()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_check);
  }

  Future<void> _check() async {
    final hasToken = await TokenStorage.accessToken() != null;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasToken ? const RoleRouter() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
