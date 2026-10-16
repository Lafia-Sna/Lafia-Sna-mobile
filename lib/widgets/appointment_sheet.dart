import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/patient_api.dart';
import '../format.dart';
import '../theme.dart';
import 'form_fields.dart';

/// Demande de rendez-vous auprès d'un service : le service confirme ou refuse ensuite.
Future<void> showAppointmentSheet(BuildContext context, ServiceDetail service) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _AppointmentForm(service: service),
  );
}

class _AppointmentForm extends StatefulWidget {
  const _AppointmentForm({required this.service});

  final ServiceDetail service;

  @override
  State<_AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<_AppointmentForm> {
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  final _reason = TextEditingController();
  late DateTime _today;
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = nowInLome();
    _today = DateTime(now.year, now.month, now.day);
    // Premier jour d'ouverture à partir d'aujourd'hui.
    _date = List.generate(8, (i) => _today.add(Duration(days: i)))
        .firstWhere((day) => _hoursOn(day) != null, orElse: () => _today);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  TimeRange? _hoursOn(DateTime day) => widget.service.hoursOn(dayOfWeek(day));

  String _iso(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  String _hhmm(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 90)),
      // Les jours de fermeture du service ne sont pas proposés.
      selectableDayPredicate: (day) => _hoursOn(day) != null,
      helpText: 'Date du rendez-vous',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time, helpText: 'Heure du rendez-vous');
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final reason = _reason.text.trim();
    try {
      await PatientApiScope.of(context).requestAppointment(
        widget.service.id,
        date: _iso(_date),
        time: _hhmm(_time),
        reason: reason.isEmpty ? null : reason,
      );
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _hoursOn(_date);

    return Padding(
      // Le formulaire remonte au-dessus du clavier.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _sent ? _confirmation(context) : _form(context, hours),
        ),
      ),
    );
  }

  Widget _confirmation(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 48, color: LafiaColors.green),
        const SizedBox(height: 12),
        Text('Demande envoyée', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '${widget.service.name} vous répondra pour confirmer le ${dayName(dayOfWeek(_date)).toLowerCase()} '
          '${_date.day} ${_months[_date.month - 1]} à ${formatTime(_hhmm(_time))}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: LafiaColors.body),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
      ],
    );
  }

  Widget _form(BuildContext context, TimeRange? hours) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Demander un rendez-vous', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('${widget.service.name} · ${widget.service.hospitalName}'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                label: 'Date',
                value: '${shortDayName(dayOfWeek(_date))} ${_date.day} ${_months[_date.month - 1]}',
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerButton(
                label: 'Heure',
                value: formatTime(_hhmm(_time)),
                icon: Icons.schedule_rounded,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: Text(
            hours == null
                ? 'Ce service est fermé ce jour-là.'
                : 'Ouvert ce jour-là : ${formatRange(hours.start, hours.end)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        LabeledField(
          label: 'Motif (facultatif)',
          controller: _reason,
          icon: Icons.notes_rounded,
          hint: 'Exemple : contrôle, vaccination',
          maxLength: 500,
          textInputAction: TextInputAction.done,
        ),
        if (_error != null) FormErrorBanner(message: _error!),
        SubmitButton(label: 'Envoyer la demande', busy: _busy, onPressed: _submit),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.label, required this.value, required this.icon, required this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LafiaColors.ink)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12)),
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: LafiaColors.subtle),
          label: Text(value, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
