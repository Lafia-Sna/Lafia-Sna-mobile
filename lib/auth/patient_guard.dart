import 'package:flutter/material.dart';

import 'auth_controller.dart';
import 'login_screen.dart';

/// Chat, rendez-vous et soins à domicile demandent un compte patient :
/// propose la connexion si besoin, puis lance [action].
/// [allowNurse] : le backend accepte un infirmier pour le chat et les rendez-vous,
/// mais pas pour une demande de soins à domicile.
Future<void> runAsPatient(BuildContext context, VoidCallback action, {bool allowNurse = true}) async {
  final user = await ensureLoggedIn(context, loginScreen: const LoginScreen());
  if (user == null || !context.mounted) return;
  if (user.role != 'patient' && !(allowNurse && user.role == 'nurse')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réservé aux comptes patient. Utilisez votre espace sur le site web.')),
    );
    return;
  }
  action();
}
