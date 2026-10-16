import 'api_client.dart';
import 'models.dart';

class HospitalsApi {
  HospitalsApi(this._client);

  final ApiClient _client;

  /// Recherche par nom ou par ville ; liste complète si [search] est vide.
  Future<List<Hospital>> list({String search = ''}) async {
    final data = await _client.get(
      '/hospitals',
      query: search.isEmpty ? null : {'search': search},
    ) as List<dynamic>;

    return data.map((item) => Hospital.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<HospitalDetail> show(int id) async {
    return HospitalDetail.fromJson(await _client.get('/hospitals/$id') as Map<String, dynamic>);
  }

  Future<ServiceDetail> service(int id) async {
    return ServiceDetail.fromJson(await _client.get('/services/$id') as Map<String, dynamic>);
  }

  // --- Compteurs anonymes du tableau de bord de l'hôpital (aucune donnée personnelle) ---

  // Une seule visite comptée par fiche et par lancement de l'appli, même si elle est rouverte.
  final _countedHospitals = <int>{};
  final _countedServices = <int>{};

  /// Ouverture d'une fiche hôpital.
  void recordHospitalVisit(int hospitalId) {
    if (!_countedHospitals.add(hospitalId)) return;
    _fireAndForget('/hospitals/$hospitalId/visits');
  }

  /// Consultation d'un service (« view ») ou appel à son secrétariat (« call »).
  void recordServiceEvent(int serviceId, ServiceEvent event) {
    if (event == ServiceEvent.view && !_countedServices.add(serviceId)) return;
    _fireAndForget('/services/$serviceId/events', {'type': event.name});
  }

  // Un échec (hors connexion) ne doit jamais gêner la lecture ni l'appel.
  void _fireAndForget(String path, [Map<String, Object?> body = const {}]) {
    _client.post(path, body).catchError((Object _) => null);
  }
}

enum ServiceEvent { view, call }
