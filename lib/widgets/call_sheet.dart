import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';

/// Feuille « Appel direct » (maquette M10) : le numéro en grand, puis l'appel en un geste.
Future<void> showCallSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String phone,
  VoidCallback? onCall,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 14, color: LafiaColors.body)),
            const SizedBox(height: 28),
            SelectableText(
              formatPhone(phone),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: LafiaColors.ink),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: LafiaColors.green,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: () async {
                onCall?.call();
                final opened = await callPhone(phone);
                if (!context.mounted) return;
                if (opened) {
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Impossible d\'ouvrir le téléphone. Composez le ${formatPhone(phone)}.')),
                  );
                }
              },
              icon: const Icon(Icons.phone_in_talk_outlined),
              label: const Text('Appeler maintenant', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ],
        ),
      ),
    ),
  );
}
