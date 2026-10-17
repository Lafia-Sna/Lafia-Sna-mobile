/// URL de l'API Laravel, fournie au lancement (jamais en dur) :
/// `flutter run --dart-define-from-file=dart_defines.json`
const String apiUrl = String.fromEnvironment('API_URL');

/// Adresse du site web (espace hôpital, administration). Facultative : vide, aucun lien n'est proposé.
const String webUrl = String.fromEnvironment('WEB_URL');
