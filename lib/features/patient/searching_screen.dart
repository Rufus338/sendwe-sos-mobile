/// P3 — Recherche en cours (SEARCHING/ASSIGNED → suivi dès ACCEPTED, section 9.B).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/ws_client.dart';
import '../../shared/call_phone.dart';
import 'track_emergency_screen.dart';

class SearchingScreen extends StatefulWidget {
  final String emergencyId;
  const SearchingScreen({super.key, required this.emergencyId});

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen> {
  bool _accepted = false;
  bool _failed = false;
  String? _failReason;
  String? _backupPhone;
  Timer? _polling;
  WSClient? _ws;

  @override
  void initState() {
    super.initState();
    _ws = WSClient(
      handlers: {
        'emergency.accepted': (_) => _goToTrack(),
        'emergency.failed': (data) => setState(() {
          _failed = true;
          _failReason = data['reason'] as String?;
        }),
      },
    );
    _ws!.connect();
    // Fallback polling si WS indisponible (toutes les 5 s, section P3)
    _polling = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final data =
          await apiClient.get('/emergencies/${widget.emergencyId}')
              as Map<String, dynamic>;
      final status = data['status'] as String;
      if (status == 'ACCEPTED') _goToTrack();
      if (status == 'FAILED') {
        setState(() {
          _failed = true;
          _failReason = 'Aucune ambulance disponible actuellement';
          // Décision 6 : numéro de secours, masqué si non configuré
          final phone = data['emergency_backup_phone'] as String?;
          _backupPhone = (phone != null && phone.isNotEmpty) ? phone : null;
        });
      }
    } catch (_) {
      /* ignore */
    }
  }

  void _goToTrack() {
    _polling?.cancel();
    _ws?.close();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TrackEmergencyScreen(emergencyId: widget.emergencyId),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    try {
      await apiClient.patch(
        '/emergencies/${widget.emergencyId}/cancel',
        body: {'reason': 'Annulé par le patient'},
      );
    } catch (_) {
      /* ignore */
    }
    _polling?.cancel();
    _ws?.close();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _polling?.cancel();
    _ws?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche d\'ambulance')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_failed) ...[
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                _failReason ??
                    'Aucune ambulance disponible actuellement, réessayez.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              // Numéro de secours : affiché UNIQUEMENT s'il est configuré (décision 6)
              if (_backupPhone != null && _backupPhone!.isNotEmpty) ...[
                const SizedBox(height: 16),
                CallButton(phone: _backupPhone!, showNumber: true),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour à l\'accueil'),
              ),
            ] else ...[
              const SizedBox(
                height: 64,
                width: 64,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 24),
              Text(
                _accepted
                    ? 'Ambulance trouvée, en attente de confirmation…'
                    : 'Recherche d\'une ambulance disponible…',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => _showCancelConfirm(),
                child: const Text('Annuler la demande'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text('Voulez-vous vraiment annuler ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancel();
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}
