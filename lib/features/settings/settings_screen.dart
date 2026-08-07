/// P8 — Paramètres (section 9.B) : permissions système + version.
/// Aucun appel API — lecture des permissions système uniquement.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationGranted = false;
  bool _notificationsGranted = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final loc = await Permission.location.status;
    final notif = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _locationGranted = loc.isGranted;
        _notificationsGranted = notif.isGranted;
      });
    }
  }

  Future<void> _openSystemSettings() async {
    await openAppSettings();
    await _loadPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Permission localisation
          SwitchListTile(
            value: _locationGranted,
            onChanged: (_) => _openSystemSettings(),
            title: const Text('Localisation'),
            subtitle: const Text('Nécessaire pour demander une ambulance'),
            secondary: Icon(
              _locationGranted ? Icons.location_on : Icons.location_off,
              color: _locationGranted ? AppColors.success : AppColors.danger,
            ),
          ),
          const Divider(),
          // Permission notifications
          SwitchListTile(
            value: _notificationsGranted,
            onChanged: (_) => _openSystemSettings(),
            title: const Text('Notifications'),
            subtitle: const Text('Alertes de suivi de votre demande'),
            secondary: Icon(
              _notificationsGranted
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: _notificationsGranted
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version de l\'application'),
            subtitle: Text('Sendwe SOS v1.0.0 (MVP)'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.phone_in_talk_outlined),
            title: Text('Numéro d\'urgence'),
            subtitle: Text(
              'Contactez directement votre hôpital en cas d\'urgence',
            ),
          ),
        ],
      ),
    );
  }
}
