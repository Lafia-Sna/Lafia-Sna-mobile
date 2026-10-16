import 'package:flutter/material.dart';

import '../location.dart';
import '../theme.dart';

/// Choix renvoyé quand la personne ne veut plus de tri par distance.
const noPlace = Place(label: '', latitude: 0, longitude: 0);

/// Maquette M05 « Où êtes-vous ? » : position du téléphone ou ville choisie.
/// Renvoie la place choisie, [noPlace] pour ne plus trier, ou `null` si la feuille est fermée.
Future<Place?> showPlaceSheet(BuildContext context, {required List<Place> cities, required Place? current}) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _PlaceSheet(cities: cities, current: current),
  );
}

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({required this.cities, required this.current});

  final List<Place> cities;
  final Place? current;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  bool _locating = false;
  String? _error;

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final place = await currentPlace();
      if (mounted) Navigator.of(context).pop(place);
    } on LocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.current;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Où êtes-vous ?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Les hôpitaux sont classés du plus proche au plus loin de cette position.'),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: LafiaColors.green, minimumSize: const Size.fromHeight(50)),
              onPressed: _locating ? null : _useGps,
              icon: _locating
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(_locating ? 'Localisation…' : 'Utiliser ma position GPS'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            const Text(
              'Votre position reste sur votre téléphone.',
              style: TextStyle(fontSize: 12),
            ),
            if (widget.cities.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text(
                'Ou choisissez une ville',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LafiaColors.ink),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final city in widget.cities)
                    ChoiceChip(
                      label: Text(city.label),
                      selected: current != null && !current.fromGps && current.label == city.label,
                      onSelected: (_) => Navigator.of(context).pop(city),
                      selectedColor: LafiaColors.blue,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: current?.label == city.label && !(current?.fromGps ?? false)
                            ? Colors.white
                            : LafiaColors.ink,
                      ),
                      shape: const StadiumBorder(side: BorderSide(color: LafiaColors.border)),
                    ),
                ],
              ),
            ],
            if (current != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(noPlace),
                child: const Text('Ne plus trier par distance'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
