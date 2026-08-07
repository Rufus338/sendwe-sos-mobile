/// Widgets partagés (section 11).

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Badge de statut : texte + couleur (accessibilité daltonisme).
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  static const _labels = {
    'AVAILABLE': 'Disponible',
    'BUSY': 'En intervention',
    'OUT_OF_SERVICE': 'Hors service',
    'OFFLINE': 'Hors ligne',
    'SEARCHING': 'Recherche…',
    'ASSIGNED': 'Assignée',
    'ACCEPTED': 'Acceptée',
    'EN_ROUTE_TO_PATIENT': 'En route',
    'ARRIVED_AT_PATIENT': 'Arrivé',
    'PATIENT_PICKED_UP': 'Pris en charge',
    'EN_ROUTE_TO_HOSPITAL': 'Vers hôpital',
    'ARRIVED_AT_HOSPITAL': 'Arrivé hôpital',
    'COMPLETED': 'Terminée',
    'CANCELLED': 'Annulée',
    'REJECTED': 'Refusée',
    'FAILED': 'Échec',
    'IN_PROGRESS': 'En cours',
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _labels[status] ?? status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _color(String status) {
    switch (status) {
      case 'AVAILABLE':
      case 'COMPLETED':
        return AppColors.success;
      case 'BUSY':
      case 'EN_ROUTE_TO_PATIENT':
      case 'ARRIVED_AT_PATIENT':
      case 'PATIENT_PICKED_UP':
      case 'EN_ROUTE_TO_HOSPITAL':
      case 'ARRIVED_AT_HOSPITAL':
      case 'IN_PROGRESS':
        return AppColors.active;
      case 'SEARCHING':
      case 'ASSIGNED':
      case 'ACCEPTED':
      case 'REQUESTED':
        return AppColors.pending;
      case 'OUT_OF_SERVICE':
      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
        return AppColors.danger;
      default:
        return AppColors.offline;
    }
  }
}

/// État de chargement explicite (section 11 — pas de spinner infini).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
