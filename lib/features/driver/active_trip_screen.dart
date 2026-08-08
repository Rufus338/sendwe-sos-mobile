/// D3 — Intervention en cours : pilotage étape par étape (section 9.C).

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/ws_client.dart';
import '../../shared/call_phone.dart';
import '../../shared/sos_map.dart';
import '../../shared/widgets.dart';

class ActiveTripScreen extends StatefulWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  Map<String, dynamic>? _trip;
  bool _loading = true;
  WSClient? _ws;

  // Bouton actif selon l'état courant (un seul à la fois, section D3)
  static const _nextAction = {
    'ACCEPTED': ('EN_ROUTE_TO_PATIENT', 'Démarrer'),
    'EN_ROUTE_TO_PATIENT': ('ARRIVED_AT_PATIENT', 'Je suis arrivé'),
    'ARRIVED_AT_PATIENT': ('PATIENT_PICKED_UP', 'Patient pris en charge'),
    'EN_ROUTE_TO_HOSPITAL': ('ARRIVED_AT_HOSPITAL', 'Arrivé à l\'hôpital'),
    'ARRIVED_AT_HOSPITAL': ('COMPLETED', 'Terminer l\'intervention'),
  };

  @override
  void initState() {
    super.initState();
    _load();
    _ws = WSClient(handlers: {'emergency.cancelled': (_) => _load()});
    _ws!.connect();
  }

  Future<void> _load() async {
    try {
      final data =
          await apiClient.get('/trips/${widget.tripId}')
              as Map<String, dynamic>;
      setState(() {
        _trip = data;
        _loading = false;
      });
      final status = data['status'] as String;
      if (status == 'COMPLETED' ||
          status == 'CANCELLED' ||
          status == 'FAILED') {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _advance() async {
    final action = _nextAction[_trip?['status']];
    if (action == null) return;
    final nextStatus = action.$1;
    final label = action.$2;

    if (nextStatus == 'PATIENT_PICKED_UP' || nextStatus == 'COMPLETED') {
      // Confirmation légère (actions non réversibles)
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(label),
          content: Text(
            nextStatus == 'COMPLETED'
                ? 'Confirmer la fin de l\'intervention ?'
                : 'Confirmer la prise en charge du patient ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    try {
      await apiClient.patch(
        '/trips/${widget.tripId}/status',
        body: {'status': nextStatus},
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  void dispose() {
    _ws?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    final status = (_trip?['status'] as String?) ?? '';
    final action = _nextAction[status];
    final beneficiary = _trip?['beneficiary_name'] as String?;
    final beneficiaryPhone = _trip?['beneficiary_phone'] as String?;
    final requesterName = _trip?['requester_name'] as String?;
    final requesterPhone = _trip?['requester_phone'] as String?;
    final isThirdParty = beneficiary != null && beneficiary.isNotEmpty;
    final reason = (_trip?['reason_category'] as String? ?? '').replaceAll(
      '_',
      ' ',
    );

    // Point de prise en charge (marqueur rouge fixe, section 19)
    final pickup = _trip?['pickup_location'] as Map<String, dynamic>?;
    LatLng? pickupPoint;
    if (pickup != null) {
      final lat = (pickup['lat'] as num?)?.toDouble();
      final lng = (pickup['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) pickupPoint = LatLng(lat, lng);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Intervention en cours')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status),
                // Bouton discret pour signaler un problème (D3)
                TextButton(
                  onPressed: () => _reportProblem(),
                  child: const Text('Signaler un problème'),
                ),
              ],
            ),
          ),
          // Carte : position du lieu d'intervention (section 19)
          Expanded(
            child: pickupPoint != null
                ? SOSMap(
                    center: pickupPoint,
                    markers: [
                      MapMarkerData(
                        id: 'pickup',
                        point: pickupPoint,
                        color: pickupMarkerColor,
                      ),
                    ],
                    interactive: true,
                  )
                : const ColoredBox(
                    color: Color(0xFFE8EEF5),
                    child: Center(
                      child: Icon(
                        Icons.place,
                        size: 64,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: AppColors.active,
                          ),
                          title: Text(beneficiary ?? requesterName ?? 'Demandeur'),
                          subtitle: Text('Motif : $reason'),
                          trailing: isThirdParty && beneficiaryPhone != null
                              ? CallButton(
                                  phone: beneficiaryPhone,
                                  compact: true,
                                )
                              : null,
                        ),
                        // Appel du demandeur : discret, si différent du bénéficiaire
                        if (isThirdParty &&
                            requesterPhone != null &&
                            requesterPhone.isNotEmpty) ...[
                          const Divider(height: 1),
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                            title: Text(
                              requesterName ?? 'Demandeur',
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: CallButton(
                              phone: requesterPhone,
                              compact: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (action != null)
                    ElevatedButton(onPressed: _advance, child: Text(action.$2))
                  else
                    const Center(child: Text('Intervention en attente…')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reportProblem() {
    String? selected;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Signaler un problème'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<String>(
                title: const Text('Ambulance en panne'),
                value: 'FAILED',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
              RadioListTile<String>(
                title: const Text('Patient introuvable'),
                value: 'FAILED',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
              RadioListTile<String>(
                title: const Text('Fausse alerte'),
                value: 'CANCELLED',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (obligatoire)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: selected != null && controller.text.trim().isNotEmpty
                  ? () {
                      final target = selected!;
                      Navigator.pop(ctx);
                      _closeWithProblem(target, controller.text.trim());
                    }
                  : null,
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closeWithProblem(String status, String reason) async {
    try {
      await apiClient.patch(
        '/trips/${widget.tripId}/status',
        body: {'status': status, 'reason': reason},
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
