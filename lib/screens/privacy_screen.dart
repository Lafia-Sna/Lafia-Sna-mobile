import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../format.dart';
import '../theme.dart';

// Mêmes coordonnées que le pied de page du site web.
const _contactEmail = 'lafiasnastartup@gmail.com';
const _contactPhone = '+22893341690';

/// Politique de confidentialité, rédigée d'après ce que l'appli et l'API font réellement.
/// BROUILLON : à faire relire par l'équipe (et idéalement un juriste) avant la publication.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidentialité', style: TextStyle(fontWeight: FontWeight.w800)),
        shape: const Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Politique de confidentialité', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Lafia Sna, Sokodé, région Centrale, Togo. Version du 15 octobre 2026.'),
            const SizedBox(height: 16),
            const _Section(
              title: 'En bref',
              paragraphs: [
                'Lafia Sna vous aide à savoir si un service hospitalier est ouvert, à joindre ce service '
                    'et à demander des soins à domicile. Nous collectons seulement ce qui est nécessaire pour cela.',
                'Consulter les hôpitaux, les services et les infirmiers ne demande aucun compte.',
                'Lafia Sna ne remplace pas une consultation. En cas de danger, appelez les secours.',
              ],
            ),
            const _Section(
              title: 'Ce que nous collectons',
              bullets: [
                'Votre compte : nom, numéro de téléphone, adresse e-mail (facultative) et mot de passe. '
                    'Le mot de passe est chiffré : personne, pas même l\'équipe, ne peut le lire.',
                'Vos messages avec l\'accueil d\'un service (chat de pré-orientation).',
                'Vos demandes de rendez-vous : service, date, heure et motif si vous en donnez un.',
                'Vos demandes de soins à domicile : adresse ou repère, soin souhaité, date souhaitée.',
                'Pour un compte infirmier : ville, région, soins proposés et présentation.',
                'Des compteurs anonymes (nombre de visites d\'une fiche, d\'appels à un service), '
                    'sans aucune information sur vous.',
              ],
            ),
            const _Section(
              title: 'Ce que nous ne collectons pas',
              bullets: [
                'Votre position : si vous utilisez « Ma position », elle sert seulement à trier les hôpitaux '
                    'sur votre téléphone. Elle n\'est jamais envoyée à nos serveurs.',
                'Vos appels : le bouton « Appeler » ouvre simplement le téléphone. Nous comptons qu\'un appel '
                    'a été lancé, sans savoir qui appelle ni ce qui est dit.',
                'Aucune publicité, aucune revente de données.',
              ],
            ),
            const _Section(
              title: 'Qui voit vos informations',
              bullets: [
                'L\'accueil d\'un service voit les messages que vous lui envoyez, votre nom et votre numéro.',
                'Un service voit vos demandes de rendez-vous qui le concernent, avec votre nom et votre numéro.',
                'Un infirmier voit votre demande de soins et votre ville. Votre adresse précise et votre numéro '
                    'ne lui sont communiqués qu\'après qu\'il a accepté la demande.',
                'Le numéro d\'un infirmier ne vous est communiqué qu\'une fois votre demande acceptée.',
                'L\'équipe Lafia Sna peut accéder aux comptes pour valider les hôpitaux et les infirmiers '
                    'et pour vous aider.',
              ],
            ),
            const _Section(
              title: 'Sur votre téléphone',
              paragraphs: [
                'Votre jeton de connexion est gardé dans l\'espace chiffré du téléphone. Il est effacé quand '
                    'vous vous déconnectez.',
              ],
            ),
            const _Section(
              title: 'Combien de temps',
              paragraphs: [
                'Vos informations sont gardées tant que votre compte existe. Un code « mot de passe oublié » '
                    'expire au bout de 15 minutes.',
              ],
            ),
            const _Section(
              title: 'Vos droits',
              paragraphs: [
                'Vous pouvez modifier votre nom, votre numéro et votre e-mail depuis votre compte sur le site web. '
                    'Vous pouvez supprimer votre compte à tout moment depuis « Mon compte » : votre compte et les '
                    'informations qui y sont liées sont alors effacés. Pour obtenir une copie de vos données, écrivez à l\'équipe.',
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Contacter l\'équipe', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri(scheme: 'mailto', path: _contactEmail)),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text(_contactEmail),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => callPhone(_contactPhone),
                    icon: const Icon(Icons.phone_outlined),
                    label: Text(formatPhone(_contactPhone)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.paragraphs = const [], this.bullets = const []});

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(fontSize: 14, height: 1.45, color: LafiaColors.body);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final paragraph in paragraphs)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(paragraph, style: body)),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: body),
                  Expanded(child: Text(bullet, style: body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Lien discret vers la politique de confidentialité.
class PrivacyLink extends StatelessWidget {
  const PrivacyLink({super.key, this.prefix});

  /// Texte avant le lien (ex. « En créant un compte, vous acceptez la »).
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (prefix != null) Text(prefix!, style: const TextStyle(fontSize: 13)),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
          ),
          child: const Text('politique de confidentialité', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
