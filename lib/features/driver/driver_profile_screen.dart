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

  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer mon mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final old = oldCtrl.text.trim();
              final nw = newCtrl.text;
              if (old.isEmpty || nw.length < 8 || nw != confCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vérifiez votre mot de passe actuel, que le nouveau fait ≥ 8 '
                      'caractères et que la confirmation correspond',
                    ),
                  ),
                );
                return;
              }
              try {
                await apiClient.patch(
                  '/auth/change-password',
                  body: {'old_password': old, 'new_password': nw},
                );
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Erreur : $e')),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mot de passe modifié')));
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: _changePassword,
                        child: const Text('Changer mon mot de passe'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _logout,
                        child: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
