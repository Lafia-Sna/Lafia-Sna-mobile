import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../format.dart';
import '../screens/messages_screen.dart';
import '../screens/my_requests_screen.dart';
import '../screens/privacy_screen.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/web_space_notice.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

/// En haut des onglets : icône « Se connecter », ou les initiales de la personne connectée.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    if (user == null) {
      return IconButton.outlined(
        tooltip: 'Se connecter',
        style: IconButton.styleFrom(
          side: const BorderSide(color: LafiaColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        ),
        icon: const Icon(Icons.person_outline_rounded, color: LafiaColors.ink),
      );
    }

    return IconButton(
      tooltip: 'Mon compte',
      onPressed: () => _showAccount(context, user),
      icon: CircleAvatar(
        radius: 20,
        backgroundColor: LafiaColors.blueSoft,
        child: Text(
          initials(user.name),
          style: const TextStyle(fontWeight: FontWeight.w700, color: LafiaColors.blueDeep),
        ),
      ),
    );
  }

  void _showAccount(BuildContext context, User user) {
    final auth = AuthScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(user.name, style: Theme.of(sheetContext).textTheme.titleLarge),
              if (user.phone != null) ...[
                const SizedBox(height: 4),
                Text(formatPhone(user.phone!)),
              ],
              if (user.managesOnWeb) ...[
                const SizedBox(height: 14),
                WebSpaceNotice(role: user.role),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: LafiaColors.blueDark),
                title: const Text('Messages'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MessagesScreen()));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_note_outlined, color: LafiaColors.blueDark),
                title: const Text('Mes demandes'),
                subtitle: const Text('Rendez-vous et soins à domicile'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MyRequestsScreen()));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined, color: LafiaColors.blueDark),
                title: const Text('Confidentialité'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()));
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  auth.logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Se déconnecter'),
              ),
              // Un super-utilisateur passe par un autre super-utilisateur.
              if (user.role != 'admin')
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: _danger, minimumSize: const Size.fromHeight(48)),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    showDialog<void>(context: context, builder: (_) => DeleteAccountDialog(auth: auth));
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Supprimer mon compte'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _danger = Color(0xFFB91C1C);

/// Suppression définitive du compte : le mot de passe est redemandé.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.auth});

  final AuthController auth;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Indiquez votre mot de passe pour confirmer.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.auth.deleteAccount(_password.text);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Votre compte a été supprimé.')));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Supprimer mon compte'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vos informations, rendez-vous, demandes et messages seront effacés. Cette action est définitive.',
              style: TextStyle(color: LafiaColors.body),
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Votre mot de passe',
              controller: _password,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _danger),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Supprimer'),
        ),
      ],
    );
  }
}
