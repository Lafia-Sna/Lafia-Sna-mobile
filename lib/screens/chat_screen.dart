import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/patient_api.dart';
import '../format.dart';
import '../theme.dart';

// Pas de WebSocket pour le MVP : on demande les nouveaux messages à intervalle court.
const _refreshEvery = Duration(seconds: 3);

const _serviceQuestions = ['Quels sont les horaires ?', 'Un médecin est-il disponible ?'];

/// Discussion par messages (maquette M11) : avec l'accueil d'un service, ou avec un infirmier à domicile.
class ChatScreen extends StatefulWidget {
  const ChatScreen._({
    required this.title,
    required this.subtitle,
    required this.open,
    this.welcome,
    this.quickQuestions = const [],
    this.phone,
  });

  /// Chat de pré-orientation avec l'accueil d'un service (ouvre la conversation si besoin).
  factory ChatScreen.service({required int serviceId, required String serviceName, required String hospitalName}) {
    return ChatScreen._(
      title: '$serviceName — $hospitalName',
      subtitle: 'Chat de pré-orientation avec l\'accueil du service',
      open: (api) async => (await api.openConversation(serviceId)).id,
      welcome: 'Bonjour, vous êtes en contact avec l\'accueil du service $serviceName ($hospitalName). '
          'Décrivez brièvement votre besoin : nous vous orientons avant votre déplacement.',
      quickQuestions: _serviceQuestions,
    );
  }

  /// Discussion avec un infirmier à domicile (ouvre la conversation si besoin).
  factory ChatScreen.nurse({required int nurseId, required String nurseName, String? nurseTitle, String? phone}) {
    return ChatScreen._(
      title: nurseName,
      subtitle: nurseTitle ?? 'Soins à domicile',
      open: (api) async => (await api.openNurseConversation(nurseId)).id,
      welcome: 'Décrivez le soin dont vous avez besoin. Votre numéro n\'est pas transmis : '
          'donnez-le dans la discussion si vous souhaitez être rappelé.',
      phone: phone,
    );
  }

  /// Discussion déjà ouverte, depuis la liste « Messages ».
  factory ChatScreen.existing({required int conversationId, required String title, required String subtitle, String? phone}) {
    return ChatScreen._(title: title, subtitle: subtitle, open: (_) async => conversationId, phone: phone);
  }

  final String title;
  final String subtitle;

  /// Renvoie l'identifiant de la conversation (en l'ouvrant côté serveur si besoin).
  final Future<int> Function(PatientApi api) open;

  /// Message d'accueil affiché par l'appli (il n'est pas enregistré sur le serveur).
  final String? welcome;
  final List<String> quickQuestions;

  /// Numéro à appeler depuis la discussion, s'il est connu.
  final String? phone;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final PatientApi _api = PatientApiScope.of(context);

  int? _conversationId;
  final _messages = <ChatMessage>[];
  int _otherLastReadId = 0;
  Object? _error;
  bool _sending = false;
  bool _polling = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Appli en arrière-plan : on arrête d'interroger le serveur (batterie, forfait).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _poll();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      _conversationId = await widget.open(_api);
      await _poll();
      _startPolling();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _startPolling() {
    _timer?.cancel();
    if (_conversationId != null) _timer = Timer.periodic(_refreshEvery, (_) => _poll());
  }

  Future<void> _poll() async {
    final conversationId = _conversationId;
    if (conversationId == null || _polling) return;
    _polling = true;
    try {
      final page = await _api.messages(conversationId, afterId: _messages.isEmpty ? 0 : _messages.last.id);
      if (!mounted) return;
      setState(() {
        _add(page.messages);
        _otherLastReadId = page.otherLastReadId;
      });
    } catch (_) {
      // Coupure passagère : le prochain rafraîchissement réessaiera.
    } finally {
      _polling = false;
    }
  }

  void _add(List<ChatMessage> incoming) {
    final known = {for (final message in _messages) message.id};
    final fresh = incoming.where((message) => !known.contains(message.id)).toList();
    if (fresh.isEmpty) return;
    _messages
      ..addAll(fresh)
      ..sort((a, b) => a.id.compareTo(b.id));
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? text]) async {
    final conversationId = _conversationId;
    final body = (text ?? _input.text).trim();
    if (conversationId == null || body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final message = await _api.sendMessage(conversationId, body);
      if (!mounted) return;
      if (text == null) _input.clear();
      setState(() => _add([message]));
    } on ApiException catch (error) {
      // Le texte reste dans le champ : la personne peut réessayer sans tout retaper.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // « Vu » s'affiche seulement sous mon dernier message.
    final lastMineId = _messages.where((m) => m.isMine).lastOrNull?.id;

    return Scaffold(
      backgroundColor: LafiaColors.background,
      appBar: AppBar(
        backgroundColor: LafiaColors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0x33FFFFFF),
              child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    widget.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xD9FFFFFF)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.phone != null)
            IconButton(
              tooltip: 'Appeler',
              icon: const Icon(Icons.phone_outlined),
              onPressed: () => callPhone(widget.phone!),
            ),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _messagesList(lastMineId)),
          _Composer(
            controller: _input,
            enabled: _conversationId != null,
            sending: _sending,
            onSend: () => _send(),
            onQuickQuestion: _send,
            quickQuestions: widget.quickQuestions,
          ),
        ],
      ),
    );
  }

  Widget _messagesList(int? lastMineId) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error is ApiException ? (_error as ApiException).userMessage : 'Impossible d\'ouvrir la discussion.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _open, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.welcome != null) _Bubble(text: widget.welcome!, isMine: false),
        if (_conversationId == null) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        for (final message in _messages)
          _Bubble(
            text: message.body,
            isMine: message.isMine,
            time: message.createdAt,
            seen: message.id == lastMineId && _otherLastReadId >= message.id,
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isMine, this.time, this.seen = false});

  final String text;
  final bool isMine;
  final DateTime? time;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    final clock = time == null ? null : '${time.hour}h${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isMine ? LafiaColors.blue : Colors.white,
                boxShadow: isMine ? null : cardShadow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: SelectableText(
                text,
                style: TextStyle(fontSize: 15, height: 1.4, color: isMine ? Colors.white : LafiaColors.ink),
              ),
            ),
            if (clock != null)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(seen ? '$clock · Vu' : clock, style: const TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.onQuickQuestion,
    required this.quickQuestions,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;
  final ValueChanged<String> onQuickQuestion;
  final List<String> quickQuestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LafiaColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (quickQuestions.isNotEmpty) SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final question in quickQuestions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(question),
                          onPressed: enabled && !sending ? () => onQuickQuestion(question) : null,
                          backgroundColor: LafiaColors.blueTint,
                          side: const BorderSide(color: LafiaColors.blueTintBorder),
                          shape: const StadiumBorder(),
                          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LafiaColors.blueDeep),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(counterText: '', hintText: 'Écrivez votre message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, _) => IconButton.filled(
                      tooltip: 'Envoyer',
                      style: IconButton.styleFrom(
                        backgroundColor: LafiaColors.blue,
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: enabled && !sending && value.text.trim().isNotEmpty ? onSend : null,
                      icon: sending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Ne remplace pas une consultation. En cas de danger, appelez les secours.',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
