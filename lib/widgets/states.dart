import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';

/// Chargement, erreur et liste vide : les trois états communs à tous les écrans.

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Chargement…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.notFoundMessage,
    this.allowNotFound = true,
  });

  final Object error;
  final VoidCallback onRetry;

  /// Message affiché quand l'API répond 404.
  final String? notFoundMessage;

  /// `false` pour une liste : un 404 y signale un problème de serveur, pas une fiche disparue.
  final bool allowNotFound;

  @override
  Widget build(BuildContext context) {
    final notFound = allowNotFound && error is ApiException && (error as ApiException).isNotFound;

    return _StateCard(
      icon: notFound ? Icons.search_off_rounded : Icons.cloud_off_rounded,
      title: notFound ? (notFoundMessage ?? 'Page introuvable.') : 'Impossible de charger les informations',
      text: notFound ? null : 'Vérifiez votre connexion, puis réessayez.',
      action: notFound
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.text, this.action});

  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _StateCard(icon: Icons.search_off_rounded, title: title, text: text, action: action);
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.title, this.text, this.action});

  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: cardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: LafiaColors.greyTint,
            child: Icon(icon, size: 32, color: LafiaColors.muted),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (text != null) ...[
            const SizedBox(height: 4),
            Text(text!, textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }
}
