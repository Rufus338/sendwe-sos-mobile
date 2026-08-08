/// Helper d'appel téléphonique natif (P3 secours, P4 ambulancier, D3 bénéficiaire).
/// Le numéro n'est jamais affiché brut si non nécessaire (section 9.P4).
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lance un appel vers [phone]. Retourne false si échec.
Future<bool> callPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

/// Bouton d'appel réutilisable (icône + label), masque le numéro par défaut.
class CallButton extends StatelessWidget {
  final String phone;
  final String? label;
  final bool showNumber;
  final bool compact;

  const CallButton({
    super.key,
    required this.phone,
    this.label,
    this.showNumber = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = label ?? (showNumber ? phone : 'Appeler');
    if (compact) {
      return IconButton(
        tooltip: 'Appeler',
        icon: const Icon(Icons.phone),
        onPressed: () => callPhone(phone),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => callPhone(phone),
      icon: const Icon(Icons.phone),
      label: Text(text),
    );
  }
}
