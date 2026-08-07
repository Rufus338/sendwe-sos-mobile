/// D5 — Profil ambulancier (section 9.C) : compte géré par l'admin, lecture seule.

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../../shared/widgets.dart';
import '../auth/login_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiClient.get('/drivers/me') as Map<String, dynamic>;
      setState(() => _profile = data);
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final refresh = await TokenStorage.refreshToken();
    if (refresh != null) {
      try {
        await apiClient.post('/auth/logout', body: {'refresh_token': refresh});
      } catch (_) {
        /* ignore */
      }
    }
    await TokenStorage.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final amb = p?['ambulance'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _loading
          ? const LoadingView()
          : ListView(
              children: [
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Nom'),
                  subtitle: Text(p?['full_name'] as String? ?? '—'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Téléphone'),
                  subtitle: Text(p?['phone'] as String? ?? '—'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.local_hospital_outlined),
                  title: const Text('Ambulance assignée'),
                  subtitle: Text(
                    amb != null
                        ? '${amb['plate_number']} — ${amb['model']}'
                        : 'Aucune ambulance assignée',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Disponibilité'),
                  subtitle: Text(
                    p?['is_available'] == true ? 'Disponible' : 'Indisponible',
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: _logout,
                    child: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
    );
  }
}
