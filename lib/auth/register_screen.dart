import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';
import '../screens/privacy_screen.dart';
import 'auth_controller.dart';

/// Maquette M02 : création d'un compte patient.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final controller in [_name, _phone, _email, _password, _confirmation]) {
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

    final email = _email.text.trim();
    try {
      await AuthScope.of(context).register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: email.isEmpty ? null : email,
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      );
      if (mounted) Navigator.of(context).pop(true);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        leading: const BackButton(color: LafiaColors.blueDark),
        title: const Text(
          'Connexion',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LafiaColors.blueDark),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: SafeArea(
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
              children: [
                Text('Créer un compte', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                const Text(
                  'Un compte patient vous permet d\'écrire aux services, de demander un rendez-vous '
                  'et des soins à domicile.',
                  style: TextStyle(fontSize: 14, color: LafiaColors.body),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration().copyWith(boxShadow: raisedShadow),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledField(
                        label: 'Nom complet',
                        controller: _name,
                        icon: Icons.person_outline_rounded,
                        hint: 'Entrez votre nom',
                        autofillHints: const [AutofillHints.name],
                        maxLength: 100,
                        errorText: error?.errorFor('name'),
                      ),
                      LabeledField(
                        label: 'Numéro de téléphone',
                        controller: _phone,
                        icon: Icons.phone_outlined,
                        hint: '90 12 34 56',
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        maxLength: 20,
                        errorText: error?.errorFor('phone'),
                      ),
                      LabeledField(
                        label: 'Adresse e-mail (facultative)',
                        controller: _email,
                        icon: Icons.mail_outline_rounded,
                        hint: 'Pour récupérer votre compte',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        errorText: error?.errorFor('email'),
                      ),
                      PasswordField(
                        label: 'Mot de passe',
                        controller: _password,
                        hint: '8 caractères minimum',
                        isNew: true,
                        errorText: error?.errorFor('password'),
                      ),
                      PasswordField(
                        label: 'Confirmer le mot de passe',
                        controller: _confirmation,
                        hint: 'Saisissez-le une seconde fois',
                        isNew: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        errorText: error?.errorFor('password_confirmation'),
                      ),
                      if (general != null) FormErrorBanner(message: general),
                      const SizedBox(height: 4),
                      SubmitButton(
                        label: 'Créer mon compte',
                        busy: _busy,
                        color: LafiaColors.green,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 4),
                      const PrivacyLink(prefix: 'En créant un compte, vous acceptez la'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LafiaColors.blueTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LafiaColors.blueTintBorder),
                  ),
                  child: const Text(
                    'Vous êtes infirmier·ère ou vous représentez un hôpital ? '
                    'Créez votre compte sur le site web Lafia Sna : il sera validé par l\'équipe.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: LafiaColors.blueDeep),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
