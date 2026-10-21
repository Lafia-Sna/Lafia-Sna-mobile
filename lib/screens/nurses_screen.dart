import 'package:flutter/material.dart';

import '../api/patient_api.dart';
import '../auth/account_button.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';
import '../widgets/lafia_logo.dart';
import '../widgets/states.dart';
import '../widgets/stars.dart';
import 'nurse_detail_screen.dart';
import 'nurse_space.dart';

/// Maquette M13 : infirmiers à domicile validés par l'équipe, filtrables par région.
class NursesScreen extends StatefulWidget {
  const NursesScreen({super.key});

  @override
  State<NursesScreen> createState() => _NursesScreenState();
}

class _NursesScreenState extends State<NursesScreen> {
  late final PatientApi _api = PatientApiScope.of(context);
  List<Nurse>? _nurses;
  Object? _error;
  String? _region;
  bool _nurseSpace = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final nurses = await _api.nurses();
      if (!mounted) return;
      setState(() {
        _nurses = nurses;
        _error = null;
      });
    } catch (error) {
      if (mounted && _nurses == null) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurses = _nurses;
    final regions = {for (final nurse in nurses ?? const <Nurse>[]) if (nurse.region != null) nurse.region!}.toList()
      ..sort();
    // Si la région choisie n'existe plus dans la liste, on revient à « Toutes ».
    final region = regions.contains(_region) ? _region : null;
    final visible = (nurses ?? const <Nurse>[]).where((n) => region == null || n.region == region).toList();

    // Un compte infirmier retrouve ici son espace soignant (maquette M16).
    final isNurse = AuthScope.of(context).user?.role == 'nurse';
    final showSpace = isNurse && _nurseSpace;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: LafiaColors.divider)),
              ),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [LafiaLogo(size: 36), SizedBox(width: 6), LafiaWordmark(), Spacer(), AccountButton()],
                  ),
                  if (isNurse) ...[
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Je demande des soins')),
                        ButtonSegment(value: true, label: Text('Espace soignant')),
                      ],
                      selected: {_nurseSpace},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) => setState(() => _nurseSpace = selection.first),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: showSpace ? const NurseSpace() : _directory(context, regions, region, visible)),
          ],
        ),
      ),
    );
  }

  Widget _directory(BuildContext context, List<String> regions, String? region, List<Nurse> visible) {
    final nurses = _nurses;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Text('Soins infirmiers à domicile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Pansements, injections et prélèvements par un infirmier diplômé d\'État.'),
          if (regions.length > 1) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              // La clé recrée le champ si la région affichée change (région disparue de la liste).
              key: ValueKey(region),
              initialValue: region,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.place_outlined, color: LafiaColors.subtle)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes les régions')),
                for (final name in regions) DropdownMenuItem(value: name, child: Text('Région $name')),
              ],
              onChanged: (value) => setState(() => _region = value),
            ),
          ],
          const SizedBox(height: 16),
          if (nurses == null)
            _error != null ? ErrorState(error: _error!, onRetry: _load) : const LoadingState()
          else if (visible.isEmpty)
            const EmptyState(
              title: 'Aucun infirmier disponible pour le moment.',
              text: 'De nouveaux infirmiers rejoignent Lafia Sna après validation par l\'équipe.',
            )
          else
            for (final nurse in visible) ...[
              _NurseCard(nurse: nurse),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

/// Nombre de soins affichés sur la carte avant « +N », comme sur le site.
const _visibleServices = 4;

class _NurseCard extends StatelessWidget {
  const _NurseCard({required this.nurse});

  final Nurse nurse;

  @override
  Widget build(BuildContext context) {
    final hidden = nurse.services.length - _visibleServices;
    final years = nurse.experienceYears;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => NurseDetailScreen(nurseId: nurse.id, initial: nurse)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NurseAvatar(name: nurse.name, photoUrl: nurse.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(nurse.name, style: Theme.of(context).textTheme.titleMedium),
                          AvailabilityPill(available: nurse.isAvailable),
                        ],
                      ),
                      if (nurse.title != null && nurse.title!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(nurse.title!, style: const TextStyle(fontSize: 13, color: LafiaColors.body)),
                      ],
                      const SizedBox(height: 6),
                      RatingBadge.from(nurse.rating),
                      const SizedBox(height: 6),
                      Text(
                        [
                          nurse.place,
                          if (years != null && years > 0) '$years an${years > 1 ? 's' : ''} d\'expérience',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (nurse.services.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final care in nurse.services.take(_visibleServices)) ServiceTag(label: care),
                            if (hidden > 0) ServiceTag(label: '+$hidden'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Text(
                            'Voir la fiche',
                            style: TextStyle(fontWeight: FontWeight.w700, color: LafiaColors.blueDark),
                          ),
                          Icon(Icons.chevron_right_rounded, color: LafiaColors.blueDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
