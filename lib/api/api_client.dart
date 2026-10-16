import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.status, [this.message, this.fieldErrors = const {}]);

  /// 0 : pas de réponse du serveur (hors connexion, délai dépassé).
  final int status;
  final String? message;

  /// Erreurs de validation Laravel (422) : champ → messages.
  final Map<String, List<String>> fieldErrors;

  bool get isNotFound => status == 404;
  bool get isOffline => status == 0;

  /// Premier message d'erreur d'un champ, à afficher sous ce champ.
  String? errorFor(String field) => fieldErrors[field]?.first;

  /// Message lisible à afficher à la personne.
  String get userMessage {
    if (isOffline) return 'Pas de connexion. Vérifiez votre réseau, puis réessayez.';
    if (fieldErrors.isNotEmpty) return fieldErrors.values.first.first;
    if (status == 429) return 'Trop d\'essais. Patientez une minute, puis réessayez.';
    if (status >= 500) return 'Le service est momentanément indisponible. Réessayez dans un instant.';
    return message ?? 'Une erreur est survenue.';
  }

  @override
  String toString() => message ?? 'Erreur API $status';
}

/// Appels à l'API Laravel. Toutes les réponses sont du JSON avec une clé `data`.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Connexion souvent faible : on laisse du temps, mais pas indéfiniment.
  static const _timeout = Duration(seconds: 20);

  /// Jeton Sanctum de la personne connectée (null si déconnectée).
  String? token;

  /// Appelé quand le serveur refuse le jeton (expiré ou révoqué).
  void Function()? onUnauthorized;

  /// GET JSON ; renvoie le contenu de la clé `data`.
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    return (await getFull(path, query: query))['data'];
  }

  /// GET JSON ; renvoie la réponse entière (`data` + `meta`).
  Future<Map<String, dynamic>> getFull(String path, {Map<String, String>? query}) async {
    final body = await _send(() => _client.get(_uri(path, query), headers: _headers()), unwrap: false);
    return body as Map<String, dynamic>;
  }

  /// POST JSON ; renvoie le contenu de la clé `data` (ou `null` pour une réponse 204).
  Future<dynamic> post(String path, [Map<String, Object?> body = const {}]) {
    return _send(() => _client.post(_uri(path), headers: _headers(json: true), body: jsonEncode(body)));
  }

  /// PUT JSON ; renvoie le contenu de la clé `data`.
  Future<dynamic> put(String path, Map<String, Object?> body) {
    return _send(() => _client.put(_uri(path), headers: _headers(json: true), body: jsonEncode(body)));
  }

  /// PATCH JSON ; renvoie le contenu de la clé `data`.
  Future<dynamic> patch(String path, [Map<String, Object?> body = const {}]) {
    return _send(() => _client.patch(_uri(path), headers: _headers(json: true), body: jsonEncode(body)));
  }

  Map<String, String> _headers({bool json = false}) {
    final current = token;
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (current != null) 'Authorization': 'Bearer $current',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    if (apiUrl.isEmpty) {
      throw ApiException(0, 'API_URL manquante : lancez avec --dart-define-from-file.');
    }

    final base = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
    return Uri.parse('$base$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request, {bool unwrap = true}) async {
    final sentWithToken = token != null;
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException {
      throw ApiException(0);
    } on TimeoutException {
      throw ApiException(0);
    } on http.ClientException {
      throw ApiException(0);
    }

    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      // Jeton expiré ou révoqué : on déconnecte proprement.
      if (response.statusCode == 401 && sentWithToken) onUnauthorized?.call();

      String? message;
      final fieldErrors = <String, List<String>>{};
      if (body is Map<String, dynamic>) {
        message = body['message'] as String?;
        final errors = body['errors'];
        if (errors is Map<String, dynamic>) {
          errors.forEach((field, messages) {
            if (messages is List && messages.isNotEmpty) fieldErrors[field] = messages.cast<String>();
          });
        }
      }
      throw ApiException(response.statusCode, message, fieldErrors);
    }

    if (!unwrap) return body;
    return body is Map<String, dynamic> ? body['data'] : null;
  }
}
