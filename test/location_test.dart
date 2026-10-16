import 'package:flutter_test/flutter_test.dart';
import 'package:lafia_sna/api/models.dart';
import 'package:lafia_sna/location.dart';

Hospital _hospital(String city, double? latitude, double? longitude) => Hospital(
      id: 1,
      name: 'Test',
      city: city,
      region: 'Centrale',
      address: null,
      latitude: latitude,
      longitude: longitude,
      servicesCount: 0,
      openServicesCount: 0,
    );

void main() {
  test('distanceKm : Lomé – Sokodé, environ 317 km à vol d\'oiseau', () {
    final km = distanceKm(6.1319, 1.2228, 8.9833, 1.1333);
    expect(km, closeTo(317, 10));
  });

  test('formatDistance arrondit comme le site web', () {
    expect(formatDistance(0.72), '700 m');
    expect(formatDistance(0.01), '50 m');
    expect(formatDistance(1.63), '1,6 km');
    expect(formatDistance(37.4), '37 km');
  });

  test('citiesFrom place chaque ville au centre de ses hôpitaux et ignore ceux sans coordonnées', () {
    final cities = citiesFrom([
      _hospital('Sokodé', 9.0, 1.1),
      _hospital('Sokodé', 9.2, 1.3),
      _hospital('Kara', 9.55, 1.19),
      _hospital('Blitta', null, null),
    ]);

    expect(cities.map((c) => c.label), ['Kara', 'Sokodé']);
    expect(cities.last.latitude, closeTo(9.1, 0.0001));
    expect(cities.last.longitude, closeTo(1.2, 0.0001));
  });
}
