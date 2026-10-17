import 'dart:async';

import 'package:flutter/material.dart';

import '../api/patient_api.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/service_icon.dart';
import '../widgets/states.dart';
import 'chat_screen.dart';

// Même rythme que le site web pour la liste des discussions.
const _refreshEvery = Duration(seconds: 5);

/// Discussions du patient avec les services, la plus récente en premier.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final PatientApi _api = PatientApiScope.of(context);
  List<ConversationSummary>? _conversations;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _timer = Timer.periodic(_refreshEvery, (_) => _load());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final conversations = await _api.conversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && _conversations == null) setState(() => _error = error);
    }
  }

  Future<void> _open(ConversationSummary conversation, _Counterpart counterpart) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen.existing(
          conversationId: conversation.id,
          title: counterpart.title,
          subtitle: counterpart.subtitle,
          phone: counterpart.phone,
        ),
      ),
    );
    // Au retour, les messages lus ne comptent plus comme « non lus ».
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _conversations;
    // Comme sur le site : un patient voit ses interlocuteurs ; un infirmier ou un agent d'hôpital voit ses patients.
    final role = AuthScope.of(context).user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w800)),
        shape: const Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: conversations == null
            ? (_error != null
                ? ListView(padding: const EdgeInsets.all(16), children: [ErrorState(error: _error!, onRetry: _load)])
                : const LoadingState())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (conversations.isEmpty)
                      const EmptyState(
                        title: 'Aucune discussion pour le moment.',
                        text: 'Ouvrez un service puis « Chat de pré-orientation » pour écrire à son accueil.',
                      )
                    else
                      Container(
                        decoration: cardDecoration(),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (var i = 0; i < conversations.length; i++) ...[
                              if (i > 0) const Divider(height: 1, color: LafiaColors.greyTint),
                              _ConversationRow(
                                conversation: conversations[i],
                                counterpart: _Counterpart.of(conversations[i], viewerRole: role),
                                onTap: () => _open(
                                  conversations[i],
                                  _Counterpart.of(conversations[i], viewerRole: role),
                                ),
                              ),
                            ],
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

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.counterpart, required this.onTap});

  final ConversationSummary conversation;
  final _Counterpart counterpart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount;
    final last = conversation.lastMessage;
    final preview = last == null ? 'Pas encore de message' : (conversation.lastMessageIsMine ? 'Vous : $last' : last);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (conversation.serviceName != null)
              ServiceIconTile(serviceName: conversation.serviceName!)
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD8F7E4),
                child: Text(
                  initials(counterpart.title),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: LafiaColors.greenInk),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counterpart.title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: unread > 0 ? LafiaColors.ink : LafiaColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Badge(
                label: Text('$unread'),
                backgroundColor: LafiaColors.blue,
                largeSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Avec qui l'on parle dans une discussion, selon qui regarde.
class _Counterpart {
  const _Counterpart({required this.title, required this.subtitle, this.phone});

  factory _Counterpart.of(ConversationSummary conversation, {required String? viewerRole}) {
    final service = '${conversation.serviceName ?? 'Service'} — ${conversation.hospitalName ?? ''}';
    if (!conversation.withNurse) {
      // Agent d'hôpital : le patient qui écrit au service, avec son numéro.
      if (viewerRole == 'staff' || viewerRole == 'admin') {
        return _Counterpart(title: conversation.patientName, subtitle: service, phone: conversation.patientPhone);
      }
      return _Counterpart(title: service, subtitle: 'Chat de pré-orientation avec l\'accueil du service');
    }
    if (viewerRole == 'patient') {
      return _Counterpart(
        title: conversation.nurseName ?? 'Infirmier',
        subtitle: conversation.nurseTitle ?? 'Soins à domicile',
        phone: conversation.nursePhone,
      );
    }
    // Infirmier : son patient, dont le numéro n'est jamais transmis par la messagerie.
    return _Counterpart(title: conversation.patientName, subtitle: 'Patient · soins à domicile');
  }

  final String title;
  final String subtitle;
  final String? phone;
}
