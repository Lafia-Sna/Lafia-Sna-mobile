import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';

enum _Step { email, code, password, done }

// Le serveur n'envoie pas plus d'un code par minute pour un même compte.
const _resendDelay = Duration(seconds: 60);

/// Mot de passe oublié : code à 6 chiffres envoyé par e-mail, puis nouveau mot de passe.
/// Seuls les comptes avec une adresse e-mail peuvent l'utiliser.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  ApiException? _error;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in [_email, _code, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> get _emailAndCode => {'email': _email.text.trim(), 'code': _code.text.trim()};

  /// Lance un appel ; passe à [next] s'il réussit, garde l'erreur sinon.
  Future<void> _run(Future<void> Function() call, _Step next) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await call();
      if (mounted) setState(() => _step = next);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    await _run(() => widget.client.post('/password/forgot', {'email': _email.text.trim()}), _Step.code);
    if (_error == null) _startResendCountdown();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = _resendDelay.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final general = error != null && error.fieldErrors.isEmpty ? error.userMessage : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié', style: TextStyle(fontWeight: FontWeight.w800)),
        shape: const Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_step != _Step.done) _Steps(current: _step.index),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._fields(error),
                  if (general != null) FormErrorBanner(message: general),
                  ..._actions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields(ApiException? error) {
    switch (_step) {
      case _Step.email:
        return [
          const Text(
            'Indiquez l\'adresse e-mail de votre compte : nous vous envoyons un code à 6 chiffres.',
            style: TextStyle(color: LafiaColors.body),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Adresse e-mail',
            controller: _email,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendCode(),
            errorText: error?.errorFor('email'),
          ),
          const Text(
            'Pas d\'e-mail sur votre compte ? Contactez l\'équipe Lafia Sna ou l\'accueil de votre hôpital.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
        ];
      case _Step.code:
        return [
          Text(
            'Si ${_email.text.trim()} a un compte, un code vient d\'y être envoyé. '
            'Pensez à regarder dans les courriers indésirables.',
            style: const TextStyle(color: LafiaColors.body),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Code à 6 chiffres',
            controller: _code,
            icon: Icons.pin_outlined,
            hint: '000000',
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _run(() => widget.client.post('/password/verify', _emailAndCode), _Step.password),
            errorText: error?.errorFor('code'),
          ),
        ];
      case _Step.password:
        return [
          PasswordField(
            label: 'Nouveau mot de passe',
            controller: _password,
            hint: '8 caractères minimum',
            isNew: true,
            errorText: error?.errorFor('password') ?? error?.errorFor('code'),
          ),
          PasswordField(
            label: 'Confirmer le mot de passe',
            controller: _confirmation,
            isNew: true,
            textInputAction: TextInputAction.done,
            errorText: error?.errorFor('password_confirmation'),
          ),
        ];
      case _Step.done:
        return [
          const Icon(Icons.check_circle_outline_rounded, size: 48, color: LafiaColors.green),
          const SizedBox(height: 12),
          Text('Mot de passe changé', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Vous pouvez vous connecter avec votre numéro et votre nouveau mot de passe. '
            'Vos autres appareils ont été déconnectés.',
            textAlign: TextAlign.center,
            style: TextStyle(color: LafiaColors.body),
          ),
          const SizedBox(height: 20),
        ];
    }
  }

  List<Widget> _actions() {
    switch (_step) {
      case _Step.email:
        return [SubmitButton(label: 'Recevoir le code', busy: _busy, onPressed: _sendCode)];
      case _Step.code:
        return [
          SubmitButton(
            label: 'Vérifier le code',
            busy: _busy,
            onPressed: () => _run(() => widget.client.post('/password/verify', _emailAndCode), _Step.password),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy || _resendIn > 0 ? null : _sendCode,
            child: Text(_resendIn > 0 ? 'Renvoyer le code (${_resendIn}s)' : 'Renvoyer le code'),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _step = _Step.email),
            child: const Text('Changer d\'adresse e-mail'),
          ),
        ];
      case _Step.password:
        return [
          SubmitButton(
            label: 'Changer le mot de passe',
            busy: _busy,
            onPressed: () => _run(
              () => widget.client.post('/password/reset', {
                ..._emailAndCode,
                'password': _password.text,
                'password_confirmation': _confirmation.text,
              }),
              _Step.done,
            ),
          ),
        ];
      case _Step.done:
        return [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Se connecter'))];
    }
  }
}

/// « 1. E-mail · 2. Code · 3. Mot de passe », l'étape en cours en bleu.
class _Steps extends StatelessWidget {
  const _Steps({required this.current});

  final int current;

  static const _labels = ['E-mail', 'Code', 'Mot de passe'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape ${current + 1} sur 3 : ${_labels[current]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= current ? LafiaColors.blue : LafiaColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${i + 1}. ${_labels[i]}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                      color: i == current ? LafiaColors.blueDark : LafiaColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
