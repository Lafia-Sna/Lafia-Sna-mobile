import 'package:flutter/material.dart';

import '../auth/account_button.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/lafia_logo.dart';

/// Numéros d'urgence repris de la maquette Figma (M18).
/// À faire confirmer par l'infirmière de l'équipe avant la mise en ligne.
const _emergencyNumbers = [
  ('Police secours', '117'),
  ('Pompiers', '118'),
  ('SAMU', '8200'),
];

/// Maquette M18 « Alertes et urgences » : numéros d'urgence en un geste.
/// Le signalement d'une personne en difficulté (phase 2) viendra quand il existera côté backend.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.onFindHospital});

  /// Ouvre l'onglet Hôpitaux.
  final VoidCallback onFindHospital;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: LafiaGradients.page),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: LafiaColors.divider)),
            ),
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 12),
            child: const Row(
              children: [LafiaLogo(size: 36), SizedBox(width: 6), LafiaWordmark(), Spacer(), AccountButton()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Alertes et urgences', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                const Text('Si une vie est en danger, appelez immédiatement les secours.'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Numéros d\'urgence', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var i = 0; i < _emergencyNumbers.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _NumberTile(label: _emergencyNumbers[i].$1, number: _emergencyNumbers[i].$2),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Trouver des urgences ouvertes', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      const Text(
                        'Choisissez votre ville dans l\'onglet Hôpitaux : ouvrez le plus proche et vérifiez '
                        'que son service Urgences est ouvert avant de partir.',
                        style: TextStyle(fontSize: 13, color: LafiaColors.body),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onFindHospital,
                        icon: const Icon(Icons.local_hospital_outlined),
                        label: const Text('Voir les hôpitaux proches'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.label, required this.number});

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Appeler $label, $number',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LafiaColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final opened = await callPhone(number);
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Impossible d\'ouvrir le téléphone. Composez le $number.')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: LafiaColors.ink),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  number,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: LafiaColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
