import 'package:flutter_test/flutter_test.dart';
import 'package:lafia_sna/api/models.dart';
import 'package:lafia_sna/format.dart';
import 'package:lafia_sna/screens/service_screen.dart' show scheduleSummary;

void main() {
  group('heures', () {
    test('formatTime enlève les zéros inutiles', () {
      expect(formatTime('07:30'), '7h30');
      expect(formatTime('17:00'), '17h');
    });

    test('formatRange affiche 24h/24 quand ouverture = fermeture', () {
      expect(formatRange('00:00', '00:00'), '24h/24');
      expect(formatRange('07:30', '16:30'), '7h30–16h30');
    });

    test('dayOfWeek suit la convention de l\'API (0 = dimanche)', () {
      expect(dayOfWeek(DateTime(2026, 10, 11)), 0); // dimanche
      expect(dayOfWeek(DateTime(2026, 10, 12)), 1); // lundi
    });
  });

  group('textes', () {
    test('initials ignore le titre Dr', () {
      expect(initials('Dr Rachida Ouro-Sama'), 'RS');
      expect(initials('Fatou Alassani'), 'FA');
      expect(initials('Yao'), 'Y');
    });

    test('formatPhone découpe un numéro togolais', () {
      expect(formatPhone('+22890101329'), '+228 90 10 13 29');
      expect(formatPhone('+33612345678'), '+33612345678');
    });

    test('normalize ignore accents et majuscules', () {
      expect(normalize('Sokodé'), 'sokode');
      expect(normalize('MATERNITÉ'), 'maternite');
    });
  });

  test('scheduleSummary regroupe les jours qui se suivent', () {
    DoctorAvailability slot(int day, String start, String end) =>
        DoctorAvailability(dayOfWeek: day, range: TimeRange(start, end), status: 'consultation');

    expect(
      scheduleSummary([for (final day in [1, 2, 3, 4, 5]) slot(day, '07:30', '16:30')]),
      'Lun–Ven 7h30–16h30',
    );
    expect(
      scheduleSummary([slot(1, '09:00', '15:00'), slot(3, '09:00', '15:00'), slot(5, '09:00', '15:00')]),
      'Lun, Mer, Ven 9h–15h',
    );
  });

  test('ServiceSummary lit le statut calculé par le backend', () {
    final service = ServiceSummary.fromJson({
      'id': 1,
      'name': 'Pédiatrie',
      'description': null,
      'is_open': false,
      'is_on_call': true,
      'today_hours': {'opens_at': '07:30', 'closes_at': '16:30'},
    });

    expect(service.status, ServiceStatus.onCall);
    expect(service.todayHours?.end, '16:30');
  });
}
