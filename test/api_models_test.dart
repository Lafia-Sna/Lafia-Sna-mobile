import 'package:flutter_test/flutter_test.dart';
import 'package:lafia_sna/api/patient_api.dart';

void main() {
  test('une conversation avec un infirmier n\'a pas de service', () {
    final conversation = ConversationSummary.fromJson({
      'id': 4,
      'status': 'open',
      'service': null,
      'nurse': {'id': 2, 'name': 'Fatou Alassani', 'title': 'Infirmière diplômée d\'État', 'phone': null},
      'patient': {'name': 'Kossi A.', 'phone': null},
      'last_message': null,
      'unread_count': 1,
    });

    expect(conversation.withNurse, isTrue);
    expect(conversation.serviceName, isNull);
    expect(conversation.nurseName, 'Fatou Alassani');
    expect(conversation.unreadCount, 1);
  });

  test('un infirmier sans liste de soins reprend l\'ancien texte libre', () {
    final nurse = Nurse.fromJson({
      'id': 1,
      'name': 'Yao Kpatcha',
      'city': 'Sokodé',
      'neighborhood': 'Kpangalam',
      'specialties': 'Injection, prélèvement',
      'services': [],
      'is_available': false,
      'rating_average': 4.5,
      'reviews_count': 2,
      'likes_count': 3,
    });

    expect(nurse.services, ['Injection', 'prélèvement']);
    expect(nurse.place, 'Sokodé · Kpangalam');
    expect(nurse.isAvailable, isFalse);
    expect(nurse.rating.average, 4.5);
  });

  test('les avis lisent la répartition des notes', () {
    final page = ReviewsPage.fromJson({
      'rating_average': 4.0,
      'reviews_count': 2,
      'likes_count': 0,
      'distribution': [
        {'rating': 5, 'count': 1},
        {'rating': 3, 'count': 1},
      ],
      'liked_by_me': false,
      'my_review': {'rating': 5, 'comment': null},
      'can_review': true,
      'reviews': [
        {'id': 1, 'author': 'Aliya A.', 'rating': 5, 'comment': 'Accueil rapide', 'created_at': '2026-10-16T08:00:00Z', 'updated_at': '2026-10-16T08:00:00Z'},
      ],
    });

    expect(page.distribution[5], 1);
    expect(page.myRating, 5);
    expect(page.reviews.single.author, 'Aliya A.');
  });
}
