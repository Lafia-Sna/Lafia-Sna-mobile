import 'package:flutter/material.dart';

import '../theme.dart';

/// Champ de formulaire de la maquette : libellé au-dessus, icône à gauche, erreur du serveur en dessous.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.maxLength = 255,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLength;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return _Labeled(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        maxLength: maxLength,
        onSubmitted: onSubmitted,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 3,
          prefixIcon: Icon(icon, color: LafiaColors.subtle),
        ),
      ),
    );
  }
}

/// Mot de passe avec le bouton « œil » pour l'afficher.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.isNew = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;

  /// Nouveau mot de passe (inscription, changement) : aide le gestionnaire de mots de passe.
  final bool isNew;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return _Labeled(
      label: widget.label,
      child: TextField(
        controller: widget.controller,
        obscureText: !_visible,
        enableSuggestions: false,
        autocorrect: false,
        maxLength: 100,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofillHints: [widget.isNew ? AutofillHints.newPassword : AutofillHints.password],
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          counterText: '',
          hintText: widget.hint,
          errorText: widget.errorText,
          errorMaxLines: 3,
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: LafiaColors.subtle),
          suffixIcon: IconButton(
            tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
            icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: LafiaColors.subtle),
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LafiaColors.ink)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Message d'erreur général au-dessus du bouton d'envoi.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
        ),
      ),
    );
  }
}

/// Bouton principal avec indicateur de chargement pendant l'envoi.
class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key, required this.label, required this.busy, required this.onPressed, this.color});

  final String label;
  final bool busy;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size.fromHeight(48)),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}
