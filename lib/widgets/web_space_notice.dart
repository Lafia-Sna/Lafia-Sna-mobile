import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../theme.dart';

/// Pour un agent d'hôpital ou l'équipe Lafia Sna : leur espace de gestion est sur le site web.
/// En attendant les retours des hôpitaux partenaires, l'appli mobile ne le reprend pas.
class WebSpaceNotice extends StatelessWidget {
  const WebSpaceNotice({super.key, required this.role});

  /// `staff` ou `admin`
  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LafiaColors.blueTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LafiaColors.blueTintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.computer_rounded, color: LafiaColors.blueDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAdmin ? 'Votre espace Lafia Sna est sur le site web' : 'Votre espace hôpital est sur le site web',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: LafiaColors.blueDeep),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'Validation des hôpitaux et des infirmiers, comptes et chiffres : connectez-vous sur le site.'
                : 'Services, horaires, médecins, gardes, rendez-vous et équipe : connectez-vous sur le site '
                    'avec le même numéro. Vos messages restent visibles ici, dans « Messages ».',
            style: const TextStyle(fontSize: 13, color: LafiaColors.blueDeep),
          ),
          if (webUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Ouvrir le site'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
