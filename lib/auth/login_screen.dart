import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/lafia_logo.dart';
import '../screens/privacy_screen.dart';
import 'auth_controller.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Maquette M01 : connexion par numéro de téléphone (identifiant du backend) et mot de passe.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthScope.of(context).login(phone: _phone.text.trim(), password: _password.text);
      if (mounted) _leave();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ouvert depuis l'appli : on revient là où on était. Premier écran : l'appli bascule seule.
  void _leave() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _openRegister() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const RegisterScreen()),
    );
    if (created == true && mounted) _leave();
  }

  void _continueWithoutAccount() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      AuthScope.of(context).continueAsGuest();
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    // Une erreur rattachée à un champ s'affiche sous ce champ ; les autres en bandeau.
    final general = error != null && error.fieldErrors.isEmpty ? error.userMessage : null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: SafeArea(
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
              children: [
                const Center(child: LafiaLogo(size: 84)),
                const SizedBox(height: 12),
                const Center(child: LafiaWordmark(fontSize: 32)),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Aide à la Santé',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LafiaColors.muted),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration().copyWith(boxShadow: raisedShadow),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Connexion', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 18),
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
                      PasswordField(
                        label: 'Mot de passe',
                        controller: _password,
                        hint: 'Votre mot de passe',
                        errorText: error?.errorFor('password'),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      if (general != null) FormErrorBanner(message: general),
                      const SizedBox(height: 4),
                      SubmitButton(label: 'Se connecter', busy: _busy, onPressed: _submit),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ForgotPasswordScreen(client: AuthScope.of(context).client),
                                  ),
                                ),
                        child: const Text('Mot de passe oublié ?'),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: LafiaColors.divider)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('ou', style: TextStyle(fontSize: 13, color: LafiaColors.subtle)),
                          ),
                          Expanded(child: Divider(color: LafiaColors.divider)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _busy ? null : _continueWithoutAccount,
                        child: const Text('Continuer sans compte'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Pas encore de compte ?', style: TextStyle(color: LafiaColors.body)),
                    TextButton(
                      onPressed: _busy ? null : _openRegister,
                      child: const Text('Créer un compte', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const PrivacyLink(prefix: 'Vos données :'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
