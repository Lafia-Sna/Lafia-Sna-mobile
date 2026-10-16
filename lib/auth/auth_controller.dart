import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';

/// Personne connectée, telle que renvoyée par `/me`, `/login` et `/register`.
class User {
  const User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.mustChangePassword,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        role: json['role'] as String,
        mustChangePassword: json['must_change_password'] == true,
      );

  final int id;
  final String name;
  final String? phone;
  final String? email;

  /// `patient` | `nurse` | `staff` | `admin`
  final String role;

  /// Compte créé par l'équipe avec un mot de passe provisoire, à changer avant tout le reste.
  final bool mustChangePassword;
}

/// État de la session : jeton gardé dans le stockage chiffré du téléphone.
class AuthController extends ChangeNotifier {
  AuthController(this._api, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true)) {
    _api.onUnauthorized = () => _clear();
  }

  static const _tokenKey = 'lafia_token';
  // « Continuer sans compte » : on ne repropose pas la connexion à chaque lancement.
  static const _guestKey = 'lafia_guest';

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  User? _user;
  bool _ready = false;
  bool _guest = false;

  User? get user => _user;

  /// Client de l'API, pour les écrans de compte qui n'ouvrent pas de session (mot de passe oublié).
  ApiClient get client => _api;
  bool get isLoggedIn => _user != null;

  /// La session enregistrée a été relue au démarrage.
  bool get isReady => _ready;

  /// Ni connecté, ni « sans compte » : on propose l'écran de connexion.
  bool get shouldAskToLogin => _user == null && !_guest;

  /// Au lancement : relit le jeton et vérifie qu'il est toujours valable.
  Future<void> restore() async {
    try {
      _guest = await _storage.read(key: _guestKey) == '1';
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        _api.token = token;
        _user = User.fromJson(await _api.get('/me') as Map<String, dynamic>);
      }
    } on ApiException catch (error) {
      // Hors connexion : on garde le jeton, la personne sera reconnue au prochain lancement.
      if (!error.isOffline) await _clear(notify: false);
    } catch (_) {
      // Stockage illisible (réinstallation, sauvegarde restaurée) : on repart de zéro.
      await _clear(notify: false);
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> login({required String phone, required String password}) {
    return _openSession('/login', {'phone': phone, 'password': password});
  }

  /// Inscription d'un patient. Les comptes infirmier et hôpital se créent sur le site web.
  Future<void> register({
    required String name,
    required String phone,
    required String? email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _openSession('/register', {
      'profile': 'patient',
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> changePassword({
    required String current,
    required String password,
    required String confirmation,
  }) async {
    final data = await _api.put('/me/password', {
      'current_password': current,
      'password': password,
      'password_confirmation': confirmation,
    });
    _user = User.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    _guest = true;
    notifyListeners();
    await _storage.write(key: _guestKey, value: '1');
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {
      // Même hors connexion, on déconnecte l'appareil.
    }
    await _clear();
  }

  Future<void> _openSession(String path, Map<String, Object?> body) async {
    final data = await _api.post(path, body) as Map<String, dynamic>;
    final token = data['token'] as String;
    _api.token = token;
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    _guest = false;
    await _storage.write(key: _tokenKey, value: token);
    notifyListeners();
  }

  Future<void> _clear({bool notify = true}) async {
    _api.token = null;
    _user = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
    if (notify) notifyListeners();
  }
}

/// Donne accès à la session dans tout l'arbre de widgets : `AuthScope.of(context)`.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({super.key, required AuthController controller, required super.child})
      : super(notifier: controller);

  static AuthController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
  }
}

/// Avant une action réservée aux comptes (chat, rendez-vous) : propose la connexion si besoin.
/// Renvoie l'utilisateur connecté, ou `null` si la personne a renoncé.
Future<User?> ensureLoggedIn(BuildContext context, {required Widget loginScreen}) async {
  final auth = AuthScope.of(context);
  if (auth.isLoggedIn) return auth.user;
  await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => loginScreen));
  return auth.user;
}
