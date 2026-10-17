import 'package:flutter/material.dart';

import '../format.dart';

/// Bandeau rouge « Urgence ? Appelez directement » vers la ligne des urgences d'un hôpital
/// (comme sur le site web et la maquette M18). N'affiche rien si l'hôpital n'a pas renseigné de ligne.
class EmergencyCallCard extends StatelessWidget {
  const EmergencyCallCard({super.key, required this.phone, required this.hospitalName});

  final String? phone;
  final String hospitalName;

  @override
  Widget build(BuildContext context) {
    final phone = this.phone;
    if (phone == null || phone.isEmpty) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: 'Appeler les urgences de $hospitalName au ${formatPhone(phone)}',
      excludeSemantics: true,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
            ),
          ),
          child: InkWell(
            onTap: () async {
              final opened = await callPhone(phone);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Impossible d\'ouvrir le téléphone. Composez le ${formatPhone(phone)}.')),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.emergency_outlined, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Urgence ? Appelez directement',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xE6FFFFFF)),
                        ),
                        Text(
                          formatPhone(phone),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'Appeler',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
