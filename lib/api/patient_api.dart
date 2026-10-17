import 'package:flutter/widgets.dart';

import 'api_client.dart';

/// Discussion ouverte avec l'accueil d'un service ou avec un infirmier à domicile.
class Conversation {
  const Conversation({required this.id});

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(id: json['id'] as int);

  final int id;
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

/// Conversation dans la liste « Messages » : avec un service d'hôpital, ou avec un infirmier.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.hospitalName,
    required this.nurseId,
    required this.nurseName,
    required this.nurseTitle,
    required this.nursePhone,
    required this.patientName,
    required this.patientPhone,
    required this.lastMessage,
    required this.lastMessageIsMine,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    final nurse = json['nurse'] as Map<String, dynamic>?;
    final patient = json['patient'] as Map<String, dynamic>? ?? const {};
    final last = json['last_message'] as Map<String, dynamic>?;
    return ConversationSummary(
      id: json['id'] as int,
      serviceId: service?['id'] as int?,
      serviceName: service?['name'] as String?,
      hospitalName: service?['hospital_name'] as String?,
      nurseId: nurse?['id'] as int?,
      nurseName: nurse?['name'] as String?,
      nurseTitle: nurse?['title'] as String?,
      nursePhone: nurse?['phone'] as String?,
      patientName: patient['name'] as String? ?? 'Patient',
      patientPhone: patient['phone'] as String?,
      lastMessage: last?['body'] as String?,
      lastMessageIsMine: last?['is_mine'] == true,
      lastMessageAt: last == null ? null : DateTime.parse(last['created_at'] as String).toLocal(),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  final int id;

  /// Renseignés pour une discussion avec un service d'hôpital.
  final int? serviceId;
  final String? serviceName;
  final String? hospitalName;

  /// Renseignés pour une discussion avec un infirmier à domicile.
  final int? nurseId;
  final String? nurseName;
  final String? nurseTitle;

  /// Numéro de l'infirmier, seulement s'il a choisi de l'afficher.
  final String? nursePhone;

  final String patientName;

  /// Numéro du patient, visible par l'accueil d'un service (jamais par un infirmier).
  final String? patientPhone;
  final String? lastMessage;
  final bool lastMessageIsMine;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get withNurse => nurseId != null;
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

/// Infirmier·ère à domicile validé·e par l'équipe (annuaire public).
class Nurse {
  const Nurse({
    required this.id,
    required this.name,
    required this.title,
    required this.city,
    required this.neighborhood,
    required this.region,
    required this.services,
    required this.description,
    required this.experienceYears,
    required this.isAvailable,
    required this.phone,
    required this.rating,
  });

  factory Nurse.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List<dynamic>? ?? const []).cast<String>();
    return Nurse(
      id: json['id'] as int,
      name: json['name'] as String,
      title: json['title'] as String?,
      city: json['city'] as String? ?? '',
      neighborhood: json['neighborhood'] as String?,
      region: json['region'] as String?,
      // Liste de soins ; à défaut, l'ancien texte libre « Pansement, injection, prélèvement ».
      services: services.isNotEmpty
          ? services
          : ((json['specialties'] as String?) ?? '')
              .split(RegExp(r'[,;/]'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      description: json['description'] as String?,
      experienceYears: json['experience_years'] as int?,
      isAvailable: json['is_available'] != false,
      phone: json['phone'] as String?,
      rating: RatingSummary.fromJson(json),
    );
  }

  final int id;
  final String name;

  /// Diplôme ou fonction (ex. « Infirmier diplômé d'État »).
  final String? title;
  final String city;
  final String? neighborhood;
  final String? region;
  final List<String> services;
  final String? description;
  final int? experienceYears;

  /// Indisponible : la fiche reste visible, mais n'accepte pas de nouvelle demande.
  final bool isAvailable;

  /// Numéro public, seulement si l'infirmier a choisi de l'afficher.
  final String? phone;
  final RatingSummary rating;

  /// « Sokodé · Komah »
  String get place => [city, if (neighborhood != null && neighborhood!.isNotEmpty) neighborhood!].join(' · ');
}

/// Note moyenne, nombre d'avis et de « J'aime » d'un hôpital ou d'un infirmier.
class RatingSummary {
  const RatingSummary({required this.average, required this.reviewsCount, required this.likesCount});

  factory RatingSummary.fromJson(Map<String, dynamic> json) => RatingSummary(
        average: (json['rating_average'] as num?)?.toDouble(),
        reviewsCount: json['reviews_count'] as int? ?? 0,
        likesCount: json['likes_count'] as int? ?? 0,
      );

  static const empty = RatingSummary(average: null, reviewsCount: 0, likesCount: 0);

  /// `null` : pas encore d'avis.
  final double? average;
  final int reviewsCount;
  final int likesCount;
}

class Review {
  const Review({required this.author, required this.rating, required this.comment, required this.updatedAt});

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        author: json['author'] as String? ?? 'Patient',
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        updatedAt: DateTime.parse((json['updated_at'] ?? json['created_at']) as String).toLocal(),
      );

  /// Prénom et initiale (« Aliya A. ») : le nom complet n'est jamais publié.
  final String author;
  final int rating;
  final String? comment;
  final DateTime updatedAt;
}

/// Avis d'un hôpital ou d'un infirmier, tels que les voit la personne qui consulte.
class ReviewsPage {
  const ReviewsPage({
    required this.summary,
    required this.distribution,
    required this.likedByMe,
    required this.myRating,
    required this.myComment,
    required this.canReview,
    required this.reviews,
  });

  factory ReviewsPage.fromJson(Map<String, dynamic> json) {
    final mine = json['my_review'] as Map<String, dynamic>?;
    return ReviewsPage(
      summary: RatingSummary.fromJson(json),
      distribution: {
        for (final item in (json['distribution'] as List<dynamic>? ?? const []))
          (item as Map<String, dynamic>)['rating'] as int: item['count'] as int,
      },
      likedByMe: json['liked_by_me'] == true,
      myRating: mine?['rating'] as int?,
      myComment: mine?['comment'] as String?,
      canReview: json['can_review'] == true,
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .map((item) => Review.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final RatingSummary summary;

  /// Nombre d'avis par note, de 5 à 1 étoiles.
  final Map<int, int> distribution;
  final bool likedByMe;
  final int? myRating;
  final String? myComment;

  /// Seuls les comptes patients peuvent donner un avis ou aimer.
  final bool canReview;

  /// Les 20 avis les plus récents.
  final List<Review> reviews;
}

/// Hôpital (`hospitals`) ou infirmier (`nurses`), comme dans les adresses de l'API.
enum ReviewTarget { hospitals, nurses }

/// Fiche de l'infirmier connecté (espace soignant).
class MyNurseProfile {
  const MyNurseProfile({
    required this.title,
    required this.city,
    required this.neighborhood,
    required this.region,
    required this.services,
    required this.description,
    required this.experienceYears,
    required this.isAvailable,
    required this.showPhone,
    required this.status,
    required this.rating,
  });

  factory MyNurseProfile.fromJson(Map<String, dynamic> json) => MyNurseProfile(
        title: json['title'] as String?,
        city: json['city'] as String?,
        neighborhood: json['neighborhood'] as String?,
        region: json['region'] as String?,
        services: (json['services'] as List<dynamic>? ?? const []).cast<String>(),
        description: json['description'] as String?,
        experienceYears: json['experience_years'] as int?,
        isAvailable: json['is_available'] == true,
        showPhone: json['show_phone'] == true,
        status: json['status'] as String,
        rating: RatingSummary.fromJson(json),
      );

  final String? title;
  final String? city;
  final String? neighborhood;
  final String? region;
  final List<String> services;
  final String? description;
  final int? experienceYears;
  final bool isAvailable;

  /// Afficher son numéro sur la fiche publique (non par défaut).
  final bool showPhone;

  /// `pending` | `approved` | `rejected` : validation par l'équipe Lafia Sna.
  final String status;
  final RatingSummary rating;

  /// Ville et région sont obligatoires pour apparaître dans l'annuaire.
  bool get isComplete => (city ?? '').isNotEmpty && (region ?? '').isNotEmpty;

  /// Corps complet de `PUT /nurse/profile` : le serveur attend toute la fiche.
  Map<String, Object?> toJson() => {
        'title': title,
        'city': city,
        'neighborhood': neighborhood,
        'region': region,
        'services': services,
        'description': description,
        'experience_years': experienceYears,
        'is_available': isAvailable,
        'show_phone': showPhone,
      };

  MyNurseProfile copyWith({bool? isAvailable}) => MyNurseProfile(
        title: title,
        city: city,
        neighborhood: neighborhood,
        region: region,
        services: services,
        description: description,
        experienceYears: experienceYears,
        isAvailable: isAvailable ?? this.isAvailable,
        showPhone: showPhone,
        status: status,
        rating: rating,
      );
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

  /// Ouvre (ou retrouve) la conversation du patient avec un infirmier.
  Future<Conversation> openNurseConversation(int nurseId) async {
    return Conversation.fromJson(await _client.post('/nurses/$nurseId/conversation') as Map<String, dynamic>);
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

  /// Fiche publique d'un infirmier validé.
  Future<Nurse> nurse(int id) async {
    return Nurse.fromJson(await _client.get('/nurses/$id') as Map<String, dynamic>);
  }

  // --- Avis et « J'aime » (lecture publique, écriture réservée aux patients) ---

  Future<ReviewsPage> reviews(ReviewTarget target, int id) async {
    return ReviewsPage.fromJson(await _client.get('/${target.name}/$id/reviews') as Map<String, dynamic>);
  }

  /// Crée ou modifie l'avis de la personne connectée (un seul par cible).
  Future<ReviewsPage> saveReview(ReviewTarget target, int id, {required int rating, String? comment}) async {
    final data = await _client.put('/${target.name}/$id/review', {'rating': rating, 'comment': comment});
    return ReviewsPage.fromJson(data as Map<String, dynamic>);
  }

  Future<ReviewsPage> deleteReview(ReviewTarget target, int id) async {
    return ReviewsPage.fromJson(await _client.delete('/${target.name}/$id/review') as Map<String, dynamic>);
  }

  Future<ReviewsPage> setLiked(ReviewTarget target, int id, {required bool liked}) async {
    final path = '/${target.name}/$id/like';
    final data = liked ? await _client.post(path) : await _client.delete(path);
    return ReviewsPage.fromJson(data as Map<String, dynamic>);
  }

  /// Annuaire public des infirmiers validés : disponibles d'abord, puis les mieux notés.
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

  /// Enregistre toute la fiche (le serveur attend tous les champs).
  Future<MyNurseProfile> updateMyNurseProfile(Map<String, Object?> profile) async {
    return MyNurseProfile.fromJson(await _client.put('/nurse/profile', profile) as Map<String, dynamic>);
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
