import 'dart:async';

import 'package:flutter/material.dart';

import '../api/hospitals_api.dart';
import '../api/models.dart';
import '../auth/account_button.dart';
import '../auth/auth_controller.dart';
import '../location.dart';
import '../theme.dart';
import '../widgets/lafia_logo.dart';
import '../widgets/place_sheet.dart';
import '../widgets/states.dart';
import '../widgets/web_space_notice.dart';
import '../widgets/stars.dart';
import '../widgets/status_pill.dart';
import 'hospital_screen.dart';

/// Maquette M03 : liste des hôpitaux, recherche par nom ou ville, filtres (M06).
class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key, required this.api});

  final HospitalsApi api;

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _search = '';
  _Filters _filters = const _Filters();
  // Ville choisie ou position du téléphone : sert seulement à trier, rien n'est envoyé au serveur.
  Place? _place;
  List<Place> _cities = const [];
  List<Hospital>? _hospitals;
  Object? _error;
  bool _loading = true;
  // Seule la réponse de la dernière recherche lancée est affichée.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hospitals = await widget.api.list(search: _search);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _hospitals = hospitals;
        _loading = false;
        // Les villes proposées viennent de la liste complète, pas d'une recherche.
        if (_search.isEmpty) _cities = citiesFrom(hospitals);
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    // On attend la fin de la frappe pour économiser la connexion.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final search = value.trim();
      if (search == _search) return;
      _search = search;
      _load();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    _search = '';
    _load();
  }

  Future<void> _openFilters(List<Hospital> hospitals) async {
    final filters = await showModalBottomSheet<_Filters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FiltersSheet(hospitals: hospitals, initial: _filters),
    );
    if (filters != null) setState(() => _filters = filters);
  }

  Future<void> _choosePlace() async {
    final place = await showPlaceSheet(context, cities: _cities, current: _place);
    if (place == null || !mounted) return;
    setState(() => _place = identical(place, noPlace) ? null : place);
  }

  /// Hôpitaux filtrés, avec leur distance ; du plus proche au plus loin si une position est choisie.
  List<(Hospital, double?)> _withDistances(List<Hospital> hospitals) {
    final place = _place;
    final entries = [
      for (final hospital in hospitals)
        (
          hospital,
          place != null && hospital.latitude != null && hospital.longitude != null
              ? distanceKm(place.latitude, place.longitude, hospital.latitude!, hospital.longitude!)
              : null,
        ),
    ];
    // Les hôpitaux sans coordonnées passent à la fin.
    if (place != null) entries.sort((a, b) => (a.$2 ?? double.infinity).compareTo(b.$2 ?? double.infinity));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final hospitals = _hospitals ?? const <Hospital>[];
    final visible = _withDistances(_filters.apply(hospitals));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            // Le geste « tirer pour actualiser » marche même quand la liste est courte.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                  place: _place,
                  onChoosePlace: _choosePlace,
                ),
              ),
              // Agent d'hôpital ou équipe : leur espace de gestion est sur le site web.
              if (AuthScope.of(context).user case final user? when user.managesOnWeb)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: WebSpaceNotice(role: user.role)),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _TitleRow(
                    hospitals: _hospitals == null ? null : [for (final (hospital, _) in visible) hospital],
                    search: _search,
                    place: _place,
                    activeFilters: _filters.count,
                    onFilters: _hospitals == null ? null : () => _openFilters(hospitals),
                  ),
                ),
              ),
              ..._body(visible),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(List<(Hospital, double?)> visible) {
    if (_hospitals == null && _loading) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: LoadingState(label: 'Chargement des hôpitaux…')),
      ];
    }

    if (_error != null && _hospitals == null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          // Une liste qui ne charge pas n'est pas une « page introuvable » : on propose de réessayer.
          sliver: SliverToBoxAdapter(child: ErrorState(error: _error!, onRetry: _load, allowNotFound: false)),
        ),
      ];
    }

    if (visible.isEmpty) {
      final hasCriteria = _search.isNotEmpty || _filters.count > 0;
      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: hasCriteria
                ? EmptyState(
                    title: _search.isNotEmpty
                        ? 'Aucun hôpital trouvé pour « $_search ».'
                        : 'Aucun hôpital ne correspond aux filtres.',
                    text: 'Essayez le nom d\'une ville, par exemple « Sokodé » ou « Kara ».',
                    action: OutlinedButton(
                      onPressed: () {
                        setState(() => _filters = const _Filters());
                        if (_search.isNotEmpty) _clearSearch();
                      },
                      child: const Text('Voir tous les hôpitaux'),
                    ),
                  )
                : const EmptyState(title: 'Aucun hôpital disponible pour le moment.'),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final (hospital, distance) = visible[index];
            return _HospitalCard(
              hospital: hospital,
              distance: distance,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => HospitalScreen(api: widget.api, hospitalId: hospital.id)),
              ),
            );
          },
        ),
      ),
    ];
  }
}

/// Bandeau blanc du haut : logo et recherche.
class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.place,
    required this.onChoosePlace,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Place? place;
  final VoidCallback onChoosePlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LafiaLogo(size: 36),
              const SizedBox(width: 6),
              const LafiaWordmark(),
              const Spacer(),
              // Comme dans le Figma : la ville (ou la position) en haut à droite.
              OutlinedButton.icon(
                onPressed: onChoosePlace,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.place_outlined, size: 18, color: LafiaColors.green),
                label: Text(
                  place == null ? 'Ma ville' : (place!.fromGps ? 'Ma position' : place!.label),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const AccountButton(),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              maxLength: 100,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Hôpital ou ville (ex. Sokodé)',
                prefixIcon: const Icon(Icons.search_rounded, color: LafiaColors.subtle),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer la recherche',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onClear,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.hospitals,
    required this.search,
    required this.place,
    required this.activeFilters,
    required this.onFilters,
  });

  final List<Hospital>? hospitals;
  final String search;
  final Place? place;
  final int activeFilters;
  final VoidCallback? onFilters;

  @override
  Widget build(BuildContext context) {
    final list = hospitals;
    String? subtitle;
    if (list != null) {
      final count = list.length;
      final withOpen = list.where((h) => h.openServicesCount > 0).length;
      subtitle = '$count établissement${count > 1 ? 's' : ''}, $withOpen avec des services ouverts.';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                search.isNotEmpty
                    ? 'Résultats pour « $search »'
                    : place != null
                        ? 'Hôpitaux près de ${place!.label}'
                        : 'Hôpitaux',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onFilters,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            side: BorderSide(color: activeFilters > 0 ? LafiaColors.blue : LafiaColors.border),
          ),
          icon: const Icon(Icons.filter_list_rounded, size: 18),
          label: Text(activeFilters > 0 ? 'Filtres ($activeFilters)' : 'Filtres'),
        ),
      ],
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital, required this.distance, required this.onTap});

  final Hospital hospital;

  /// Distance à vol d'oiseau en km, si une position est choisie.
  final double? distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = hospital.openServicesCount;
    final total = hospital.servicesCount;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HospitalTile(name: hospital.name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hospital.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: LafiaColors.ink),
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 8),
                            Pill(label: formatDistance(distance!), icon: Icons.place_outlined),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${hospital.city}, région ${hospital.region}', style: const TextStyle(fontSize: 13)),
                      if (hospital.reviewsCount > 0) ...[
                        const SizedBox(height: 4),
                        RatingBadge(average: hospital.ratingAverage, count: hospital.reviewsCount),
                      ],
                      const SizedBox(height: 10),
                      SegmentedBar(filled: open, total: total),
                      const SizedBox(height: 10),
                      Pill(
                        label: '$open/$total service${total > 1 ? 's' : ''} ouvert${open > 1 ? 's' : ''}',
                        tone: open > 0 ? PillTone.green : PillTone.grey,
                        dot: false,
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

/// Carré dégradé avec le type d'établissement (« CHR », « Clinique »…).
class HospitalTile extends StatelessWidget {
  const HospitalTile({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final firstWord = name.split(' ').first;
    final label = firstWord.length <= 8 ? firstWord : firstWord.substring(0, 1).toUpperCase();

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: LafiaGradients.tile, borderRadius: BorderRadius.circular(12)),
      child: ExcludeSemantics(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: label.length <= 4 ? 14 : 11,
          ),
        ),
      ),
    );
  }
}

/// Filtres appliqués sur l'appareil (la liste complète est déjà chargée).
class _Filters {
  const _Filters({this.region, this.openNow = false});

  final String? region;
  final bool openNow;

  int get count => (region != null ? 1 : 0) + (openNow ? 1 : 0);

  List<Hospital> apply(List<Hospital> hospitals) => hospitals
      .where((h) => region == null || h.region == region)
      .where((h) => !openNow || h.openServicesCount > 0)
      .toList();
}

/// Maquette M06 : feuille de filtres.
class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.hospitals, required this.initial});

  final List<Hospital> hospitals;
  final _Filters initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _region = widget.initial.region;
  late bool _openNow = widget.initial.openNow;

  @override
  Widget build(BuildContext context) {
    final regions = {for (final h in widget.hospitals) h.region}.toList()..sort();
    final filters = _Filters(region: _region, openNow: _openNow);
    final count = filters.apply(widget.hospitals).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtres', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            const Text('Région', style: TextStyle(fontWeight: FontWeight.w600, color: LafiaColors.ink)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _region,
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes les régions')),
                for (final region in regions) DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: (value) => setState(() => _region = value),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: LafiaColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _openNow,
                onChanged: (value) => setState(() => _openNow = value ?? false),
                activeColor: LafiaColors.green,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Au moins un service ouvert maintenant',
                  style: TextStyle(fontWeight: FontWeight.w600, color: LafiaColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(const _Filters()),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(filters),
                    child: Text('Voir $count hôpita${count > 1 ? 'ux' : 'l'}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
