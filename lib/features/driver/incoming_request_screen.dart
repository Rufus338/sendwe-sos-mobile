/// D2 — Demande assignée : accepter/refuser dans les 30 s (section 9.C).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'active_trip_screen.dart';

class IncomingRequestScreen extends StatefulWidget {
  final String tripId;
  const IncomingRequestScreen({super.key, required this.tripId});

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen> {
  static const _timeout = 30;
  int _remaining = _timeout;
  Timer? _timer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        // Timeout → refus automatique côté serveur ; l'app ferme le modal
        setState(() => _expired = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _respond(String action) async {
    _timer?.cancel();
    try {
      await apiClient.patch('/trips/${widget.tripId}/$action', body: {});
      if (!mounted) return;
      if (action == 'accept') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ActiveTripScreen(tripId: widget.tripId),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          false, // modal non-fermable par simple retour arrière (section D2)
      child: Scaffold(
        body: Container(
          color: AppColors.active,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notification_important,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nouvelle intervention',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Une demande d\'ambulance vous est assignée',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  if (_expired)
                    const Text(
                      'Demande expirée',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                  else ...[
                    Text(
                      '$_remaining s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.active,
                            ),
                            onPressed: () => _respond('accept'),
                            child: const Text(
                              'Accepter',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                            onPressed: () => _confirmReject(),
                            child: const Text('Refuser'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmReject() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le refus ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _respond('reject');
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
