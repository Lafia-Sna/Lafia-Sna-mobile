import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/patient_api.dart';
import '../format.dart';
import '../theme.dart';
import 'form_fields.dart';

/// Maquette M12 : demande de soins à domicile adressée à un infirmier précis.
Future<void> showCareRequestSheet(BuildContext context, Nurse nurse) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _CareRequestForm(nurse: nurse),
  );
}

class _CareRequestForm extends StatefulWidget {
  const _CareRequestForm({required this.nurse});

  final Nurse nurse;

  @override
  State<_CareRequestForm> createState() => _CareRequestFormState();
}

class _CareRequestFormState extends State<_CareRequestForm> {
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  final _address = TextEditingController();
  final _details = TextEditingController();
  String? _care;

  /// `null` : dès que possible.
  DateTime? _date;
  bool _busy = false;
  bool _sent = false;
  ApiException? _error;

  @override
  void dispose() {
    _address.dispose();
    _details.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = nowInLome();
    return DateTime(now.year, now.month, now.day);
  }

  String _formatDate(DateTime day) => '${dayName(dayOfWeek(day)).toLowerCase()} ${day.day} ${_months[day.month - 1]}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? _today.add(const Duration(days: 1)),
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 90)),
      helpText: 'Date souhaitée',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    // Le soin choisi et les précisions forment la description envoyée à l'infirmier.
    final description = [if (_care != null) _care!, _details.text.trim()].where((part) => part.isNotEmpty).join(' : ');
    final date = _date;
    try {
      await PatientApiScope.of(context).requestCare(
        widget.nurse.id,
        address: _address.text.trim(),
        description: description,
        preferredDate: date == null
            ? null
            : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _sent ? _confirmation(context) : _form(context),
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
          '${widget.nurse.name} va l\'examiner. Son numéro vous sera communiqué dans « Mes demandes » '
          'dès qu\'elle sera acceptée.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: LafiaColors.body),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final error = _error;
    final general = error != null && error.fieldErrors.isEmpty ? error.userMessage : null;
    final date = _date;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Demander des soins à domicile', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('${widget.nurse.name}, ${widget.nurse.city}'),
        if (widget.nurse.specialties.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _Label('Quel soin ?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final care in widget.nurse.specialties)
                ChoiceChip(
                  label: Text(care),
                  selected: _care == care,
                  onSelected: (selected) => setState(() => _care = selected ? care : null),
                  selectedColor: LafiaColors.blue,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _care == care ? Colors.white : LafiaColors.ink,
                  ),
                  showCheckmark: false,
                  shape: const StadiumBorder(side: BorderSide(color: LafiaColors.border)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        const _Label('Quand ?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Dès que possible'),
              selected: date == null,
              onSelected: (_) => setState(() => _date = null),
              selectedColor: LafiaColors.blue,
              showCheckmark: false,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, color: date == null ? Colors.white : LafiaColors.ink),
            ),
            ChoiceChip(
              label: Text(date == null ? 'Planifier' : _formatDate(date)),
              avatar: Icon(Icons.calendar_today_outlined, size: 16, color: date != null ? Colors.white : LafiaColors.ink),
              selected: date != null,
              onSelected: (_) => _pickDate(),
              selectedColor: LafiaColors.blue,
              showCheckmark: false,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, color: date != null ? Colors.white : LafiaColors.ink),
            ),
          ],
        ),
        if (error?.errorFor('preferred_date') != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error!.errorFor('preferred_date')!, style: const TextStyle(color: Color(0xFFB91C1C))),
          ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Quartier et repère',
          controller: _address,
          icon: Icons.place_outlined,
          hint: 'Ex. Komah, près du marché',
          errorText: error?.errorFor('address'),
        ),
        LabeledField(
          label: widget.nurse.specialties.isEmpty ? 'Soin souhaité' : 'Précisions',
          controller: _details,
          icon: Icons.notes_rounded,
          hint: 'Ex. injection quotidienne, ordonnance disponible',
          maxLength: 400,
          textInputAction: TextInputAction.done,
          errorText: error?.errorFor('description'),
        ),
        const Text(
          'L\'infirmier·ère vous appellera au numéro de votre compte après avoir accepté.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (general != null) FormErrorBanner(message: general),
        SubmitButton(
          label: 'Envoyer la demande',
          busy: _busy,
          color: LafiaColors.green,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LafiaColors.ink)),
    );
  }
}
