import 'package:flutter/material.dart';

import '../format.dart';

const _icons = <(String, IconData)>[
  ('urgence', Icons.emergency_outlined),
  ('maternite', Icons.favorite_border_rounded),
  ('pediatrie', Icons.child_care_rounded),
  ('ophtalmo', Icons.visibility_outlined),
  ('radio', Icons.document_scanner_outlined),
  ('trauma', Icons.healing_outlined),
  ('bloc', Icons.content_cut_rounded),
  ('labo', Icons.science_outlined),
  ('pharmacie', Icons.medication_outlined),
  ('cardio', Icons.monitor_heart_outlined),
  ('dentaire', Icons.mood_outlined),
  ('medecine', Icons.medical_services_outlined),
];

/// Pictogramme d'un service d'après son nom (même règle que le site web).
IconData serviceIcon(String serviceName) {
  final name = normalize(serviceName);
  for (final (keyword, icon) in _icons) {
    if (name.contains(keyword)) return icon;
  }
  return Icons.medical_services_outlined;
}

/// Carré bleu clair avec le pictogramme du service.
class ServiceIconTile extends StatelessWidget {
  const ServiceIconTile({super.key, required this.serviceName, this.size = 40});

  final String serviceName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFFEEF6FF), borderRadius: BorderRadius.circular(size / 4)),
      child: Icon(serviceIcon(serviceName), color: const Color(0xFF0A52A6), size: size * 0.5),
    );
  }
}
