/// P5 — Résumé d'intervention (section 9.B).

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import 'patient_home_screen.dart';

class SummaryScreen extends StatefulWidget {
  final String emergencyId;
  const SummaryScreen({super.key, required this.emergencyId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await apiClient.get('/emergencies/${widget.emergencyId}')
              as Map<String, dynamic>;
      setState(() => _data = data);
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intervention terminée')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 72,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre intervention est terminée',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.emergency),
                      title: const Text('Motif'),
                      subtitle: Text(
                        ((_data?['reason_category'] as String?) ?? '—')
                            .replaceAll('_', ' '),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const PatientHomeScreen(),
                      ),
                      (route) => false,
                    ),
                    child: const Text('Retour à l\'accueil'),
                  ),
                ],
              ),
            ),
    );
  }
}
