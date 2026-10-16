import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/patient_api.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/states.dart';
import '../widgets/status_pill.dart';

const _regions = ['Maritime', 'Plateaux', 'Centrale', 'Kara', 'Savanes'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

// Une nouvelle demande doit apparaître sans que l'infirmier ait à rafraîchir.
const _refreshEvery = Duration(seconds: 30);

/// Maquette M16 : disponibilité, fiche et demandes de soins reçues par l'infirmier connecté.
class NurseSpace extends StatefulWidget {
  const NurseSpace({super.key});

  @override
  State<NurseSpace> createState() => _NurseSpaceState();
}

class _NurseSpaceState extends State<NurseSpace> {
  late final PatientApi _api = PatientApiScope.of(context);
  MyNurseProfile? _profile;
  List<ReceivedCareRequest>? _requests;
  Object? _error;
  bool _savingAvailability = false;
  final _responding = <int>{};
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
      final results = await Future.wait([_api.myNurseProfile(), _api.receivedCareRequests()]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as MyNurseProfile;
        _requests = results[1] as List<ReceivedCareRequest>;
        _error = null;
      });
    } catch (error) {
      if (mounted && _profile == null) setState(() => _error = error);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setAvailable(bool available) async {
    final profile = _profile;
    if (profile == null || profile.isAvailable == available) return;
    if (!profile.isComplete) {
      _showMessage('Complétez d\'abord votre ville et votre région dans « Ma fiche ».');
      return;
    }

    setState(() => _savingAvailability = true);
    try {
      final updated = await _api.updateMyNurseProfile(
        city: profile.city!,
        region: profile.region!,
        specialties: profile.specialties,
        description: profile.description,
        isAvailable: available,
      );
      if (mounted) setState(() => _profile = updated);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _savingAvailability = false);
    }
  }

  Future<void> _respond(ReceivedCareRequest request, String status) async {
    setState(() => _responding.add(request.id));
    try {
      await _api.respondToCareRequest(request.id, status);
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _responding.remove(request.id));
    }
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await showModalBottomSheet<MyNurseProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProfileForm(api: _api, profile: profile),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final requests = _requests;

    if (profile == null || requests == null) {
      return _error != null
          ? ListView(padding: const EdgeInsets.all(16), children: [ErrorState(error: _error!, onRetry: _load)])
          : const LoadingState();
    }

    final open = requests.where((r) => r.status == 'pending' || r.status == 'accepted').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (profile.status != 'approved') _ValidationBanner(status: profile.status),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.isComplete ? '${profile.city}, région ${profile.region}' : 'Fiche à compléter',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Ma fiche'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ma disponibilité',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LafiaColors.ink),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Disponible')),
                    ButtonSegment(value: false, label: Text('Indisponible')),
                  ],
                  selected: {profile.isAvailable},
                  showSelectedIcon: false,
                  onSelectionChanged: _savingAvailability ? null : (selection) => _setAvailable(selection.first),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.isAvailable
                      ? 'Vous apparaissez dans l\'annuaire et pouvez recevoir des demandes.'
                      : 'Vous n\'apparaissez plus dans l\'annuaire. Vos demandes en cours restent visibles.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Demandes reçues ($open)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (requests.isEmpty)
            const EmptyState(title: 'Aucune demande pour le moment.')
          else
            for (final request in requests) ...[
              _RequestCard(
                request: request,
                busy: _responding.contains(request.id),
                onRespond: (status) => _respond(request, status),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rejected ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rejected
            ? 'Votre fiche n\'a pas été validée par l\'équipe Lafia Sna. Contactez-la pour en savoir plus.'
            : 'Votre fiche attend la validation de l\'équipe Lafia Sna. Vous apparaîtrez dans l\'annuaire ensuite.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: rejected ? const Color(0xFF991B1B) : const Color(0xFF92400E),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.busy, required this.onRespond});

  final ReceivedCareRequest request;
  final bool busy;
  final ValueChanged<String> onRespond;

  @override
  Widget build(BuildContext context) {
    final date = request.preferredDate;
    final when = date == null
        ? 'Dès que possible'
        : 'Le ${dayName(dayOfWeek(date)).toLowerCase()} ${date.day} ${_months[date.month - 1]}';
    final phone = request.patientPhone;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(request.patientName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: request.status == 'pending'
                ? const Pill(label: 'Nouvelle demande', tone: PillTone.amber)
                : RequestStatusPill(status: request.status, feminine: true),
          ),
          const SizedBox(height: 10),
          Text(
            [when, if (request.address != null) request.address!].join(', '),
            style: const TextStyle(fontSize: 13, color: LafiaColors.body),
          ),
          const SizedBox(height: 4),
          Text('« ${request.description} »', style: const TextStyle(fontSize: 13)),
          if (request.status == 'pending') ...[
            const SizedBox(height: 6),
            const Text(
              'L\'adresse précise et le numéro du patient s\'affichent après acceptation.',
              style: TextStyle(fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          if (busy)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (request.status == 'pending') ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: LafiaColors.green),
                    onPressed: () => onRespond('accepted'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accepter'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onRespond('declined'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Refuser'),
                  ),
                ],
                if (request.status == 'accepted') ...[
                  if (phone != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: LafiaColors.green),
                      onPressed: () => callPhone(phone),
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: Text('Appeler ${formatPhone(phone)}'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => onRespond('done'),
                    icon: const Icon(Icons.task_alt_rounded, size: 18),
                    label: const Text('Soin effectué'),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Ma fiche : ville, région, soins proposés et présentation, visibles dans l'annuaire.
class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.api, required this.profile});

  final PatientApi api;
  final MyNurseProfile profile;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _city = TextEditingController(text: widget.profile.city);
  late final _specialties = TextEditingController(text: widget.profile.specialties);
  late final _description = TextEditingController(text: widget.profile.description);
  late String? _region = _regions.contains(widget.profile.region) ? widget.profile.region : null;
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _city.dispose();
    _specialties.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    String? orNull(TextEditingController controller) =>
        controller.text.trim().isEmpty ? null : controller.text.trim();

    try {
      final updated = await widget.api.updateMyNurseProfile(
        city: _city.text.trim(),
        region: _region ?? '',
        specialties: orNull(_specialties),
        description: orNull(_description),
        isAvailable: widget.profile.isAvailable,
      );
      if (mounted) Navigator.of(context).pop(updated);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final general = error != null && error.fieldErrors.isEmpty ? error.userMessage : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ma fiche', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Ces informations sont visibles des patients dans l\'annuaire.'),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Ville',
                controller: _city,
                icon: Icons.location_city_outlined,
                hint: 'Ex. Sokodé',
                maxLength: 100,
                errorText: error?.errorFor('city'),
              ),
              const Text('Région', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LafiaColors.ink)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _region,
                hint: const Text('Choisir…'),
                decoration: InputDecoration(errorText: error?.errorFor('region')),
                items: [for (final region in _regions) DropdownMenuItem(value: region, child: Text(region))],
                onChanged: (value) => setState(() => _region = value),
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'Soins proposés (facultatif)',
                controller: _specialties,
                icon: Icons.medical_services_outlined,
                hint: 'Pansements, injections, prélèvements',
                errorText: error?.errorFor('specialties'),
              ),
              LabeledField(
                label: 'Présentation (facultative)',
                controller: _description,
                icon: Icons.notes_rounded,
                hint: 'Ex. Infirmier diplômé d\'État, 8 ans d\'expérience',
                maxLength: 500,
                textInputAction: TextInputAction.done,
                errorText: error?.errorFor('description'),
              ),
              if (general != null) FormErrorBanner(message: general),
              SubmitButton(label: 'Enregistrer', busy: _busy, onPressed: _submit),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
            ],
          ),
        ),
      ),
    );
  }
}
