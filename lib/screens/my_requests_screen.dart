import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/patient_api.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/states.dart';
import '../widgets/status_pill.dart';

const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

String _formatDate(DateTime date) =>
    '${dayName(dayOfWeek(date)).toLowerCase()} ${date.day} ${_months[date.month - 1]}';

/// Maquette M15 : rendez-vous demandés aux services et demandes de soins à domicile.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late final PatientApi _api = PatientApiScope.of(context);
  List<Appointment>? _appointments;
  List<CareRequest>? _careRequests;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_api.appointments(), _api.careRequests()]);
      if (!mounted) return;
      setState(() {
        _appointments = results[0] as List<Appointment>;
        _careRequests = results[1] as List<CareRequest>;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Demande une confirmation, annule, puis recharge la liste.
  Future<void> _cancel(String question, Future<void> Function() cancel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(question),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Oui, annuler')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await cancel();
      await _load();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _appointments;
    final careRequests = _careRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes', style: TextStyle(fontWeight: FontWeight.w800)),
        shape: const Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: appointments == null || careRequests == null
            ? (_error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [ErrorState(error: _error!, onRetry: _load)],
                  )
                : const LoadingState())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Text('Rendez-vous', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (appointments.isEmpty)
                      const EmptyState(
                        title: 'Aucun rendez-vous demandé.',
                        text: 'Ouvrez un service puis « Demander un rendez-vous ».',
                      ),
                    for (final appointment in appointments) ...[
                      _AppointmentCard(
                        appointment: appointment,
                        onCancel: () => _cancel(
                          'Annuler ce rendez-vous ?',
                          () => _api.cancelAppointment(appointment.id),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    Text('Soins à domicile', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (careRequests.isEmpty) const EmptyState(title: 'Aucune demande de soins à domicile.'),
                    for (final request in careRequests) ...[
                      _CareRequestCard(
                        request: request,
                        onCancel: () => _cancel(
                          'Annuler cette demande de soins ?',
                          () => _api.cancelCareRequest(request.id),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.title, required this.status, required this.lines, this.highlight, this.actions = const []});

  final String title;
  final Widget status;
  final List<String> lines;

  /// Bandeau vert (« Passage prévu… ») sous les détails.
  final String? highlight;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [Text(title, style: Theme.of(context).textTheme.titleMedium), status],
          ),
          for (final line in lines) ...[
            const SizedBox(height: 6),
            Text(line, style: const TextStyle(fontSize: 13, color: LafiaColors.body)),
          ],
          if (highlight != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: LafiaColors.greenTint, borderRadius: BorderRadius.circular(8)),
              child: Text(
                highlight!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LafiaColors.greenInk),
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onCancel});

  final Appointment appointment;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final when = '${_formatDate(appointment.date)} à ${formatTime(appointment.time)}';

    return _RequestCard(
      title: appointment.serviceName,
      status: RequestStatusPill(status: appointment.status),
      lines: [
        '${appointment.hospitalName}, $when',
        if (appointment.reason != null) 'Motif : ${appointment.reason}',
        if (appointment.responseNote != null) 'Réponse du service : ${appointment.responseNote}',
      ],
      highlight: appointment.status == 'confirmed' ? 'Rendez-vous prévu : $when' : null,
      actions: [
        if (appointment.canCancel)
          OutlinedButton(onPressed: onCancel, child: const Text('Annuler le rendez-vous')),
      ],
    );
  }
}

class _CareRequestCard extends StatelessWidget {
  const _CareRequestCard({required this.request, required this.onCancel});

  final CareRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final date = request.preferredDate;
    final when = date == null ? 'Dès que possible' : 'Le ${_formatDate(date)}';
    final phone = request.nursePhone;

    return _RequestCard(
      title: request.description,
      status: RequestStatusPill(status: request.status, feminine: true),
      lines: [
        [when, if (request.address != null) request.address!].join(', '),
        'Infirmier·ère : ${request.nurseName}${request.nurseCity != null ? ' (${request.nurseCity})' : ''}',
      ],
      highlight: request.status == 'accepted' && date != null ? 'Passage prévu : le ${_formatDate(date)}' : null,
      actions: [
        // Le numéro n'est communiqué qu'une fois la demande acceptée.
        if (phone != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: LafiaColors.green),
            onPressed: () => callPhone(phone),
            icon: const Icon(Icons.phone_outlined, size: 18),
            label: Text('Appeler ${request.nurseName}'),
          ),
        if (request.canCancel) OutlinedButton(onPressed: onCancel, child: const Text('Annuler la demande')),
      ],
    );
  }
}
