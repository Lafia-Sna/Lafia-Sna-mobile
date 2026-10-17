import 'package:flutter/material.dart';

import '../api/patient_api.dart';
import '../auth/auth_controller.dart';
import '../auth/patient_guard.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/care_request_sheet.dart';
import '../widgets/reviews_section.dart';
import '../widgets/states.dart';
import '../widgets/stars.dart';
import '../widgets/status_pill.dart';
import 'chat_screen.dart';

/// Fiche publique d'un infirmier à domicile : présentation, soins, contact et avis (comme sur le site).
class NurseDetailScreen extends StatefulWidget {
  const NurseDetailScreen({super.key, required this.nurseId, this.initial});

  final int nurseId;

  /// Carte de l'annuaire : affichée tout de suite, pendant que la fiche complète se charge.
  final Nurse? initial;

  @override
  State<NurseDetailScreen> createState() => _NurseDetailScreenState();
}

class _NurseDetailScreenState extends State<NurseDetailScreen> {
  late final PatientApi _api = PatientApiScope.of(context);
  late Nurse? _nurse = widget.initial;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final nurse = await _api.nurse(widget.nurseId);
      if (mounted) {
        setState(() {
          _nurse = nurse;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && _nurse == null) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurse = _nurse;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Soins à domicile',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LafiaColors.blueDark),
        ),
        shape: const Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: nurse == null
            ? (_error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ErrorState(
                        error: _error!,
                        onRetry: _load,
                        notFoundMessage: 'Cet infirmier n\'est plus dans l\'annuaire.',
                      ),
                    ],
                  )
                : const LoadingState(label: 'Chargement de la fiche…'))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _Header(nurse: nurse),
                    const SizedBox(height: 14),
                    _Contact(nurse: nurse),
                    const SizedBox(height: 14),
                    _Details(nurse: nurse),
                    const SizedBox(height: 14),
                    ReviewsSection(target: ReviewTarget.nurses, id: nurse.id, name: nurse.name),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.nurse});

  final Nurse nurse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NurseAvatar(name: nurse.name, radius: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nurse.name, style: Theme.of(context).textTheme.headlineSmall),
                if (nurse.title != null && nurse.title!.isNotEmpty)
                  Text(nurse.title!, style: const TextStyle(color: LafiaColors.body)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [AvailabilityPill(available: nurse.isAvailable), RatingBadge.from(nurse.rating)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Écrire, appeler (si l'infirmier affiche son numéro) et planifier un soin.
class _Contact extends StatelessWidget {
  const _Contact({required this.nurse});

  final Nurse nurse;

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final phone = nurse.phone;
    final firstName = nurse.name.split(' ').first;
    final canPlan = nurse.isAvailable && (user == null || user.role == 'patient');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Contacter $firstName', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            phone != null
                ? 'Écrivez-lui par la messagerie Lafia Sna ou appelez directement.'
                : 'Écrivez-lui par la messagerie Lafia Sna : il vous répondra ici.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: LafiaColors.green),
                  // Le backend accepte aussi un infirmier comme patient pour écrire.
                  onPressed: () => runAsPatient(
                    context,
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen.nurse(
                          nurseId: nurse.id,
                          nurseName: nurse.name,
                          nurseTitle: nurse.title,
                          phone: phone,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Écrire'),
                ),
              ),
              if (phone != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => callPhone(phone),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Appeler'),
                  ),
                ),
              ],
            ],
          ),
          if (canPlan) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => runAsPatient(context, () => showCareRequestSheet(context, nurse), allowNurse: false),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Planifier un soin (adresse et date)'),
            ),
          ],
          if (!nurse.isAvailable)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: LafiaColors.greyTint, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Cet infirmier ne prend pas de nouvelles demandes pour le moment. Vous pouvez quand même lui écrire.',
                style: TextStyle(fontSize: 13, color: LafiaColors.body),
              ),
            ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.nurse});

  final Nurse nurse;

  @override
  Widget build(BuildContext context) {
    final years = nurse.experienceYears;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Fact(
            icon: Icons.place_outlined,
            label: 'Zone',
            value: nurse.place,
            detail: nurse.region != null ? 'région ${nurse.region}' : null,
          ),
          _Fact(
            icon: Icons.work_outline_rounded,
            label: 'Expérience',
            value: years != null && years > 0 ? '$years an${years > 1 ? 's' : ''}' : 'Non renseignée',
          ),
          const _Fact(icon: Icons.verified_outlined, label: 'Vérification', value: 'Validé par Lafia Sna'),
          if (nurse.description != null && nurse.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Présentation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(nurse.description!, style: const TextStyle(fontSize: 14, color: LafiaColors.body)),
          ],
          const SizedBox(height: 14),
          Text('Soins proposés', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (nurse.services.isEmpty)
            const Text('Non renseignés.')
          else
            for (final care in nurse.services)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 18, color: LafiaColors.greenInk),
                    const SizedBox(width: 8),
                    Expanded(child: Text(care, style: const TextStyle(fontSize: 14, color: LafiaColors.ink))),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value, this.detail});

  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: LafiaColors.greyTint, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: LafiaColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                if (detail != null) Text(detail!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille verte avec les initiales de l'infirmier.
class NurseAvatar extends StatelessWidget {
  const NurseAvatar({super.key, required this.name, this.radius = 24});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD8F7E4),
      child: Text(
        initials(name).isEmpty ? '?' : initials(name),
        style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.w700, color: LafiaColors.greenInk),
      ),
    );
  }
}

class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({super.key, required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    return available ? const Pill(label: 'Disponible') : const Pill(label: 'Indisponible', tone: PillTone.grey);
  }
}

/// Soin proposé, en petite étiquette grise.
class ServiceTag extends StatelessWidget {
  const ServiceTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: LafiaColors.greyTint, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LafiaColors.body)),
    );
  }
}
