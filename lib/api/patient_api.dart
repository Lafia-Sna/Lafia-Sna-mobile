import 'package:flutter/widgets.dart';

import 'api_client.dart';

class Conversation {
  const Conversation({required this.id, required this.serviceName, required this.hospitalName});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>;
    return Conversation(
      id: json['id'] as int,
      serviceName: service['name'] as String,
      hospitalName: service['hospital_name'] as String,
    );
  }

  final int id;
  final String serviceName;
  final String hospitalName;
}

class ChatMessage {
  const ChatMessage({required this.id, required this.body, required this.isMine, required this.createdAt});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        body: json['body'] as String,
        isMine: json['is_mine'] == true,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  final int id;
  final String body;
  final bool isMine;
  final DateTime createdAt;
}

/// Nouveaux messages et dernier message lu par l'autre personne (pour la mention « Vu »).
class MessagePage {
  const MessagePage(this.messages, this.otherLastReadId);

  final List<ChatMessage> messages;
  final int otherLastReadId;
}

/// Conversation dans la liste « Messages ».
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.hospitalName,
    required this.lastMessage,
    required this.lastMessageIsMine,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>;
    final last = json['last_message'] as Map<String, dynamic>?;
    return ConversationSummary(
      id: json['id'] as int,
      serviceId: service['id'] as int,
      serviceName: service['name'] as String,
      hospitalName: service['hospital_name'] as String,
      lastMessage: last?['body'] as String?,
      lastMessageIsMine: last?['is_mine'] == true,
      lastMessageAt: last == null ? null : DateTime.parse(last['created_at'] as String).toLocal(),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  final int id;
  final int serviceId;
  final String serviceName;
  final String hospitalName;
  final String? lastMessage;
  final bool lastMessageIsMine;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
    required this.responseNote,
    required this.serviceId,
    required this.serviceName,
    required this.hospitalName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>;
    return Appointment(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      reason: json['reason'] as String?,
      status: json['status'] as String,
      responseNote: json['response_note'] as String?,
      serviceId: service['id'] as int,
      serviceName: service['name'] as String,
      hospitalName: service['hospital_name'] as String,
    );
  }

  final int id;
  final DateTime date;

  /// « HH:MM »
  final String time;
  final String? reason;

  /// `pending` | `confirmed` | `declined` | `cancelled`
  final String status;

  /// Réponse du service (créneau proposé, pièces à apporter…).
  final String? responseNote;
  final int serviceId;
  final String serviceName;
  final String hospitalName;

  bool get canCancel => status == 'pending' || status == 'confirmed';
}

class CareRequest {
  const CareRequest({
    required this.id,
    required this.description,
    required this.preferredDate,
    required this.status,
    required this.address,
    required this.nurseName,
    required this.nurseCity,
    required this.nursePhone,
  });

  factory CareRequest.fromJson(Map<String, dynamic> json) {
    final nurse = json['nurse'] as Map<String, dynamic>;
    final preferred = json['preferred_date'] as String?;
    return CareRequest(
      id: json['id'] as int,
      description: json['description'] as String,
      preferredDate: preferred == null ? null : DateTime.parse(preferred),
      status: json['status'] as String,
      address: json['address'] as String?,
      nurseName: nurse['name'] as String,
      nurseCity: nurse['city'] as String?,
      nursePhone: nurse['phone'] as String?,
    );
  }

  final int id;
  final String description;

  /// `null` : dès que possible.
  final DateTime? preferredDate;

  /// `pending` | `accepted` | `declined` | `done` | `cancelled`
  final String status;
  final String? address;
  final String nurseName;
  final String? nurseCity;

  /// Numéro de l'infirmier, communiqué seulement une fois la demande acceptée.
  final String? nursePhone;

  bool get canCancel => status == 'pending' || status == 'accepted';
}

/// Infirmier·ère à domicile validé·e par l'équipe (annuaire public, sans numéro).
class Nurse {
  const Nurse({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.specialties,
    required this.description,
  });

  factory Nurse.fromJson(Map<String, dynamic> json) => Nurse(
        id: json['id'] as int,
        name: json['name'] as String,
        city: json['city'] as String? ?? '',
        region: json['region'] as String?,
        // Texte libre saisi par l'infirmier : « Pansement, injection, prélèvement ».
        specialties: ((json['specialties'] as String?) ?? '')
            .split(RegExp(r'[,;/]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        description: json['description'] as String?,
      );

  final int id;
  final String name;
  final String city;
  final String? region;
  final List<String> specialties;
  final String? description;
}

/// Fiche de l'infirmier connecté (espace soignant).
class MyNurseProfile {
  const MyNurseProfile({
    required this.city,
    required this.region,
    required this.specialties,
    required this.description,
    required this.isAvailable,
    required this.status,
  });

  factory MyNurseProfile.fromJson(Map<String, dynamic> json) => MyNurseProfile(
        city: json['city'] as String?,
        region: json['region'] as String?,
        specialties: json['specialties'] as String?,
        description: json['description'] as String?,
        isAvailable: json['is_available'] == true,
        status: json['status'] as String,
      );

  final String? city;
  final String? region;
  final String? specialties;
  final String? description;
  final bool isAvailable;

  /// `pending` | `approved` | `rejected` : validation par l'équipe Lafia Sna.
  final String status;

  /// Ville et région sont obligatoires pour apparaître dans l'annuaire.
  bool get isComplete => (city ?? '').isNotEmpty && (region ?? '').isNotEmpty;
}

/// Demande de soins reçue par l'infirmier connecté.
class ReceivedCareRequest {
  const ReceivedCareRequest({
    required this.id,
    required this.description,
    required this.preferredDate,
    required this.status,
    required this.address,
    required this.patientName,
    required this.patientPhone,
  });

  factory ReceivedCareRequest.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>? ?? const {};
    final preferred = json['preferred_date'] as String?;
    return ReceivedCareRequest(
      id: json['id'] as int,
      description: json['description'] as String,
      preferredDate: preferred == null ? null : DateTime.parse(preferred),
      status: json['status'] as String,
      address: json['address'] as String?,
      patientName: patient['name'] as String? ?? 'Patient',
      patientPhone: patient['phone'] as String?,
    );
  }

  final int id;
  final String description;
  final DateTime? preferredDate;

  /// `pending` | `accepted` | `declined` | `done`
  final String status;

  /// Adresse précise et numéro : communiqués seulement après acceptation.
  final String? address;
  final String patientName;
  final String? patientPhone;
}

/// Actions d'une personne connectée : chat, rendez-vous, soins à domicile, espace soignant.
class PatientApi {
  PatientApi(this._client);

  final ApiClient _client;

  /// Ouvre (ou retrouve) la conversation du patient avec un service.
  Future<Conversation> openConversation(int serviceId) async {
    return Conversation.fromJson(await _client.post('/services/$serviceId/conversation') as Map<String, dynamic>);
  }

  /// Messages de la conversation ; avec [afterId], seulement les nouveaux (économise la connexion).
  Future<MessagePage> messages(int conversationId, {int afterId = 0}) async {
    final response = await _client.getFull(
      '/conversations/$conversationId/messages',
      query: afterId > 0 ? {'after': '$afterId'} : null,
    );
    final meta = response['meta'] as Map<String, dynamic>? ?? const {};
    return MessagePage(
      (response['data'] as List<dynamic>)
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta['other_last_read_message_id'] as int? ?? 0,
    );
  }

  Future<ChatMessage> sendMessage(int conversationId, String body) async {
    return ChatMessage.fromJson(
      await _client.post('/conversations/$conversationId/messages', {'body': body}) as Map<String, dynamic>,
    );
  }

  Future<List<ConversationSummary>> conversations() async {
    final data = await _client.get('/conversations') as List<dynamic>;
    return data.map((item) => ConversationSummary.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Appointment>> appointments() async {
    final data = await _client.get('/appointments') as List<dynamic>;
    return data.map((item) => Appointment.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> cancelAppointment(int id) => _client.patch('/appointments/$id/cancel');

  Future<List<CareRequest>> careRequests() async {
    final data = await _client.get('/care-requests') as List<dynamic>;
    return data.map((item) => CareRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> cancelCareRequest(int id) => _client.patch('/care-requests/$id/cancel');

  /// Annuaire public : seuls les infirmiers validés et disponibles y figurent.
  Future<List<Nurse>> nurses() async {
    final data = await _client.get('/nurses') as List<dynamic>;
    return data.map((item) => Nurse.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// [preferredDate] « AAAA-MM-JJ », ou `null` pour « dès que possible ».
  Future<void> requestCare(int nurseId, {required String address, required String description, String? preferredDate}) {
    return _client.post('/nurses/$nurseId/requests', {
      'address': address,
      'description': description,
      'preferred_date': preferredDate,
    });
  }

  // --- Espace soignant (comptes infirmier) ---

  Future<MyNurseProfile> myNurseProfile() async {
    return MyNurseProfile.fromJson(await _client.get('/nurse/profile') as Map<String, dynamic>);
  }

  Future<MyNurseProfile> updateMyNurseProfile({
    required String city,
    required String region,
    required String? specialties,
    required String? description,
    required bool isAvailable,
  }) async {
    final data = await _client.put('/nurse/profile', {
      'city': city,
      'region': region,
      'specialties': specialties,
      'description': description,
      'is_available': isAvailable,
    });
    return MyNurseProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ReceivedCareRequest>> receivedCareRequests() async {
    final data = await _client.get('/nurse/requests') as List<dynamic>;
    return data.map((item) => ReceivedCareRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// [status] : `accepted`, `declined` ou `done`.
  Future<void> respondToCareRequest(int id, String status) => _client.patch('/nurse/requests/$id', {'status': status});

  /// [date] « AAAA-MM-JJ », [time] « HH:MM ».
  Future<void> requestAppointment(int serviceId, {required String date, required String time, String? reason}) {
    return _client.post('/services/$serviceId/appointments', {'date': date, 'time': time, 'reason': reason});
  }
}

/// Donne accès aux appels « patient » dans tout l'arbre de widgets : `PatientApiScope.of(context)`.
class PatientApiScope extends InheritedWidget {
  const PatientApiScope({super.key, required this.api, required super.child});

  final PatientApi api;

  static PatientApi of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PatientApiScope>()!.api;
  }

  @override
  bool updateShouldNotify(PatientApiScope oldWidget) => api != oldWidget.api;
}
