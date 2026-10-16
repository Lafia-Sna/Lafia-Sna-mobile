import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'api/models.dart';

/// Point de référence pour trier les hôpitaux : une ville choisie, ou la position du téléphone.
/// La position reste sur le téléphone : elle n'est ni envoyée au serveur, ni enregistrée.
class Place {
  const Place({required this.label, required this.latitude, required this.longitude, this.fromGps = false});

  /// « Sokodé », ou « vous » pour la position GPS (« Hôpitaux près de vous »).
  final String label;
  final double latitude;
  final double longitude;
  final bool fromGps;
}

/// Une ville est placée au centre de ses hôpitaux : pas besoin de service de cartographie.
List<Place> citiesFrom(List<Hospital> hospitals) {
  final byCity = <String, List<Hospital>>{};
  for (final hospital in hospitals) {
    if (hospital.latitude != null && hospital.longitude != null) {
      byCity.putIfAbsent(hospital.city, () => []).add(hospital);
    }
  }

  return byCity.entries.map((entry) {
    final list = entry.value;
    return Place(
      label: entry.key,
      latitude: list.map((h) => h.latitude!).reduce((a, b) => a + b) / list.length,
      longitude: list.map((h) => h.longitude!).reduce((a, b) => a + b) / list.length,
    );
  }).toList()
    ..sort((a, b) => a.label.compareTo(b.label));
}

const _earthRadiusKm = 6371.0;

/// Distance à vol d'oiseau en kilomètres (formule de haversine, comme sur le site web).
double distanceKm(double fromLatitude, double fromLongitude, double toLatitude, double toLongitude) {
  double radians(double degrees) => degrees * pi / 180;
  final deltaLatitude = radians(toLatitude - fromLatitude);
  final deltaLongitude = radians(toLongitude - fromLongitude);
  final a = pow(sin(deltaLatitude / 2), 2) +
      cos(radians(fromLatitude)) * cos(radians(toLatitude)) * pow(sin(deltaLongitude / 2), 2);
  return 2 * _earthRadiusKm * asin(sqrt(a));
}

/// « 800 m », « 4,2 km », « 37 km ».
String formatDistance(double km) {
  if (km < 1) return '${max(50, (km * 20).round() * 50)} m';
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;
}

/// Position approximative du téléphone, demandée seulement quand la personne appuie sur « Utiliser ma position ».
Future<Place> currentPlace() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('La localisation est désactivée. Activez-la dans les réglages du téléphone.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Position refusée. Choisissez plutôt une ville.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Position refusée. Autorisez-la dans les réglages du téléphone, ou choisissez une ville.',
      );
    }

    // Position récente déjà connue du téléphone : réponse immédiate, sans attendre le GPS.
    final last = await Geolocator.getLastKnownPosition();
    if (last != null && DateTime.now().difference(last.timestamp) < const Duration(minutes: 30)) {
      return _placeFrom(last);
    }

    try {
      // Précision moyenne : suffisante pour comparer des villes, et trouvée plus vite à l'intérieur que le GPS fin.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 30)),
      );
      return _placeFrom(position);
    } on TimeoutException {
      // Mieux vaut une position ancienne que rien : les hôpitaux ne bougent pas.
      if (last != null) return _placeFrom(last);
      throw const LocationException(
        'Le téléphone ne trouve pas sa position. Activez le GPS (ou le Wi-Fi) et réessayez, ou choisissez une ville.',
      );
    }
  } on LocationException {
    rethrow;
  } on MissingPluginException {
    throw const LocationException('La position n\'est pas disponible sur cet appareil. Choisissez une ville.');
  } catch (error) {
    // Seul le type d'erreur est affiché en développement, jamais la position.
    debugPrint('Localisation impossible : ${error.runtimeType}');
    throw const LocationException('Position introuvable pour le moment. Réessayez, ou choisissez une ville.');
  }
}

Place _placeFrom(Position position) =>
    Place(label: 'vous', latitude: position.latitude, longitude: position.longitude, fromGps: true);
