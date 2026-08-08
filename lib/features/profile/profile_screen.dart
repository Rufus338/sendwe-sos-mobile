/// P7 — Profil patient (section 9.B).

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullName = TextEditingController();
  String? _phone;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiClient.get('/users/me') as Map<String, dynamic>;
      _fullName.text = data['full_name'] as String;
      _phone = data['phone'] as String;
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      await apiClient.patch(
        '/users/me',
        body: {'full_name': _fullName.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil enregistré')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
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

  /// Suppression de compte — double confirmation (saisie du mot-clé) + anonymisation backend.
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Votre compte et vos données personnelles seront supprimés. '
          'Cette action est définitive. Taper SUPPRIMER pour confirmer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Taper SUPPRIMER'),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: controller.text.trim().toUpperCase() == 'SUPPRIMER'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Supprimer définitivement'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await apiClient.delete('/users/me');
      await TokenStorage.clear();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: _phone),
                    enabled:
                        false, // lecture seule au MVP (re-vérification requise)
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (non modifiable)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Enregistrer'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _logout,
                    child: const Text('Se déconnecter'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Paramètres'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _deleteAccount,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Supprimer mon compte'),
                  ),
                ],
              ),
            ),
    );
  }
}
