import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';
import 'auth_controller.dart';

/// Compte créé par l'équipe : le mot de passe provisoire doit être changé avant tout le reste.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final controller in [_current, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Une fois le mot de passe changé, l'appli bascule seule vers l'accueil.
      await AuthScope.of(context).changePassword(
        current: _current.text,
        password: _password.text,
        confirmation: _confirmation.text,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final general = error != null && error.fieldErrors.isEmpty ? error.userMessage : null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            children: [
              Text('Choisissez votre mot de passe', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Votre compte a été créé avec un mot de passe provisoire. Remplacez-le pour continuer.',
                style: TextStyle(fontSize: 14, color: LafiaColors.body),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PasswordField(
                      label: 'Mot de passe provisoire',
                      controller: _current,
                      errorText: error?.errorFor('current_password'),
                    ),
                    PasswordField(
                      label: 'Nouveau mot de passe',
                      controller: _password,
                      hint: '8 caractères minimum',
                      isNew: true,
                      errorText: error?.errorFor('password'),
                    ),
                    PasswordField(
                      label: 'Confirmer le nouveau mot de passe',
                      controller: _confirmation,
                      isNew: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      errorText: error?.errorFor('password_confirmation'),
                    ),
                    if (general != null) FormErrorBanner(message: general),
                    SubmitButton(label: 'Enregistrer', busy: _busy, onPressed: _submit),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => AuthScope.of(context).logout(),
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
