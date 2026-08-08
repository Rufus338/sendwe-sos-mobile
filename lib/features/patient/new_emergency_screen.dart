/// P2 — Nouvelle demande (section 9.B : demandeur/bénéficiaire, motif).

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/sos_map.dart';
import 'searching_screen.dart';

class NewEmergencyScreen extends StatefulWidget {
  const NewEmergencyScreen({super.key});

  @override
  State<NewEmergencyScreen> createState() => _NewEmergencyScreenState();
}

class _NewEmergencyScreenState extends State<NewEmergencyScreen> {
  bool _forSelf = true;
  String? _reasonCategory;
  final _reasonNote = TextEditingController();
  final _beneficiaryName = TextEditingController();
  final _beneficiaryPhone = TextEditingController();

  double? _lat;
  double? _lng;
  String? _error;
  bool _loading = false;
  bool _locating = false;

  static const _categories = [
    ('ACCIDENT', 'Accident'),
    ('OBSTETRIC', 'Urgence obstétricale'),
    ('SEVERE_ILLNESS', 'Malaise / maladie grave'),
    ('OTHER', 'Autre'),
  ];

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      setState(() => _error = 'Impossible de déterminer votre position');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// P2 — pickup_location éditable : pin déplaçable sur carte interactive.
  Future<void> _pickOnMap() async {
    if (_lat == null || _lng == null) return;
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(
          initial: LatLng(_lat!, _lng!),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _lat = picked.latitude;
        _lng = picked.longitude;
        _error = null;
      });
    }
  }

  bool get _canSubmit {
    if (_reasonCategory == null || _lat == null || _lng == null) return false;
    if (!_forSelf) {
      if (_beneficiaryName.text.trim().isEmpty ||
          _beneficiaryPhone.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await apiClient.post(
                '/emergencies',
                body: {
                  'pickup_location': {'lat': _lat, 'lng': _lng},
                  'reason_category': _reasonCategory,
                  'reason_note': _reasonNote.text.trim().isEmpty
                      ? null
                      : _reasonNote.text.trim(),
                  'is_for_self': _forSelf,
                  'beneficiary_name': _forSelf
                      ? null
                      : _beneficiaryName.text.trim(),
                  'beneficiary_phone': _forSelf
                      ? null
                      : _beneficiaryPhone.text.trim(),
                },
              )
              as Map<String, dynamic>;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SearchingScreen(emergencyId: data['id'] as String),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connexion impossible, vérifiez votre réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle demande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sélecteur demandeur / bénéficiaire (P2)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Pour moi')),
                ButtonSegment(
                  value: false,
                  label: Text('Pour quelqu\'un d\'autre'),
                ),
              ],
              selected: {_forSelf},
              onSelectionChanged: (s) => setState(() => _forSelf = s.first),
            ),
            const SizedBox(height: 16),

            // Localisation (pré-remplie par GPS, éditable — P2)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: _locating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_on, color: AppColors.active),
                    title: const Text('Position'),
                    subtitle: Text(
                      _lat != null
                          ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                          : 'GPS indisponible',
                    ),
                    trailing: TextButton(
                      onPressed: _locate,
                      child: const Text('Réessayer'),
                    ),
                  ),
                  if (_lat != null)
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.edit_location_alt,
                        size: 20,
                        color: AppColors.active,
                      ),
                      title: const Text(
                        'Choisir sur la carte',
                        style: TextStyle(fontSize: 13),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                      ),
                      onTap: _pickOnMap,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Motif (pas de champ de gravité — décision 5)
            const Text(
              'Motif de la demande',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._categories.map(
              (c) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(c.$2),
                value: c.$1,
                groupValue: _reasonCategory,
                onChanged: (v) => setState(() => _reasonCategory = v),
              ),
            ),
            TextField(
              controller: _reasonNote,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                hintText: 'Précisions utiles à l\'ambulancier',
              ),
            ),

            // Champs bénéficiaire si pour un tiers (P2)
            if (!_forSelf) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _beneficiaryName,
                decoration: const InputDecoration(
                  labelText: 'Nom de la personne à secourir',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _beneficiaryPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone sur place',
                  hintText: '+243 ...',
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading || !_canSubmit ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmer la demande'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plein écran de sélection du point de prise en charge (P2).
/// Le pin reste fixe au centre ; on déplace la carte pour ajuster la position.
class _LocationPickerScreen extends StatefulWidget {
  final LatLng initial;
  const _LocationPickerScreen({required this.initial});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Position de l\'intervention'),
        actions: [
          if (selected != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('Valider'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SOSPointPicker(
              initial: widget.initial,
              onChanged: (p) => setState(() => _selected = p),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected != null
                          ? '${selected.latitude.toStringAsFixed(5)}, '
                                '${selected.longitude.toStringAsFixed(5)}'
                          : 'Déplacez la carte pour positionner le pin',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(selected),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
