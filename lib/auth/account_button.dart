import 'package:flutter/material.dart';

import '../format.dart';
import '../screens/messages_screen.dart';
import '../screens/my_requests_screen.dart';
import '../screens/privacy_screen.dart';
import '../theme.dart';
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
            ],
          ),
        ),
      ),
    );
  }
}
