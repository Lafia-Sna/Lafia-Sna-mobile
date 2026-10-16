import 'package:url_launcher/url_launcher.dart';

const _shortDays = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
const _days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

/// Ordre d'affichage : la semaine commence le lundi (0 = dimanche).
const weekOrder = [1, 2, 3, 4, 5, 6, 0];

String shortDayName(int dayOfWeek) => _shortDays[dayOfWeek];
String dayName(int dayOfWeek) => _days[dayOfWeek];

/// Heure de Lomé (UTC+0, sans heure d'été), quel que soit le fuseau du téléphone.
DateTime nowInLome() => DateTime.now().toUtc();

/// 0 = dimanche … 6 = samedi, comme l'API.
int dayOfWeek(DateTime date) => date.weekday % 7;

/// « 07:30 » → minutes depuis minuit.
int minutesOf(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// « 07:30 » → « 7h30 », « 17:00 » → « 17h ».
String formatTime(String time) {
  final parts = time.split(':');
  final minutes = parts[1] == '00' ? '' : parts[1];
  return '${int.parse(parts[0])}h$minutes';
}

/// Même heure d'ouverture et de fermeture : ouvert en continu.
bool isAllDay(String start, String end) => start == end;

String formatRange(String start, String end) =>
    isAllDay(start, end) ? '24h/24' : '${formatTime(start)}–${formatTime(end)}';

/// « Dr Kossi Agbéko » → « KA ».
String initials(String fullName) {
  final words = fullName
      .replaceFirst(RegExp(r'^(Dr|Pr)\.?\s+', caseSensitive: false), '')
      .split(RegExp(r'[\s-]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  final last = words.length > 1 ? words.last[0] : '';
  return (words.first[0] + last).toUpperCase();
}

/// Comparaison sans accents ni majuscules : « sokode » trouve « Sokodé ».
String normalize(String text) {
  const from = 'àâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ';
  const to = 'aaaeeeeiioouuucAAAEEEEIIOOUUUC';
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString().toLowerCase();
}

/// « +22890123456 » → « +228 90 12 34 56 ».
String formatPhone(String phone) {
  final match = RegExp(r'^\+228(\d{2})(\d{2})(\d{2})(\d{2})$').firstMatch(phone);
  if (match == null) return phone;
  return '+228 ${match.group(1)} ${match.group(2)} ${match.group(3)} ${match.group(4)}';
}

/// Ouvre le composeur du téléphone. Renvoie `false` si aucun composeur n'est disponible.
Future<bool> callPhone(String phone) {
  return launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));
}

/// Itinéraire vers l'hôpital dans l'application de cartes du téléphone.
Future<bool> openDirections(double latitude, double longitude) {
  return launchUrl(
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'),
    mode: LaunchMode.externalApplication,
  );
}
