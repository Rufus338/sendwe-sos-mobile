/// P5 — Résumé d'intervention (section 9.B).

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'patient_home_screen.dart';

class SummaryScreen extends StatefulWidget {
  final String emergencyId;
  const SummaryScreen({super.key, required this.emergencyId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _timestamps;
  bool _loading = true;

  static const _stepLabels = {
    'assigned_at': 'Ambulance trouvée',
    'accepted_at': 'Ambulance acceptée',
    'started_at': 'Ambulance en route',
    'arrived_at_patient_at': 'Arrivée sur place',
    'picked_up_at': 'Patient pris en charge',
    'arrived_at_hospital_at': 'Arrivée à l\'hôpital',
    'completed_at': 'Intervention terminée',
  };

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
      // Vue patient scoped (décision 12) : horodatages de SA demande
      Map<String, dynamic>? timestamps;
      try {
        final view =
            await apiClient.get('/trips/active-for/${widget.emergencyId}')
                as Map<String, dynamic>?;
        timestamps = view?['timestamps'] as Map<String, dynamic>?;
      } catch (_) {
        timestamps = null;
      }
      if (mounted) {
        setState(() {
          _data = data;
          _timestamps = timestamps;
        });
      }
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatStep(String key, String? iso) {
    final dt = iso == null ? null : DateTime.tryParse(iso);
    if (dt == null) return '';
    final t = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    final label = _stepLabels[key] ?? key.replaceAll('_', ' ');
    return '$label — $t';
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
                  // Timeline des étapes (section P5 : récap horaires par étape)
                  if (_timestamps != null && _timestamps!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Déroulement',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final entry in _stepLabels.entries)
                              if (_timestamps![entry.key] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatStep(
                                            entry.key,
                                            _timestamps![entry.key] as String?,
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
