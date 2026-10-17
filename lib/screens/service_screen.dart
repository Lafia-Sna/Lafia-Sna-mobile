import 'dart:async';

import 'package:flutter/material.dart';

import '../api/hospitals_api.dart';
import '../api/models.dart';
import '../auth/patient_guard.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/appointment_sheet.dart';
import '../widgets/call_sheet.dart';
import '../widgets/emergency_call.dart';
import '../widgets/service_icon.dart';
import '../widgets/states.dart';
import '../widgets/status_pill.dart';
import 'chat_screen.dart';
import 'hospital_screen.dart' show serviceHint;

const _refreshEvery = Duration(minutes: 1);
const _minutesPerDay = 24 * 60;

/// Maquettes M08 et M09 : un service, ses horaires de la semaine, ses médecins et l'appel direct.
class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key, required this.api, required this.serviceId, this.siblings = const []});

  final HospitalsApi api;
  final int serviceId;

  /// Autres services du même hôpital, pour passer de l'un à l'autre sans revenir en arrière.
  final List<ServiceSummary> siblings;

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  late int _serviceId = widget.serviceId;
  ServiceDetail? _detail;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_refreshEvery, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final requested = _serviceId;
    try {
      final detail = await widget.api.service(requested);
      if (!mounted || requested != _serviceId) return;
      setState(() {
        _detail = detail;
        _error = null;
      });
      widget.api.recordServiceEvent(detail.id, ServiceEvent.view);
    } catch (error) {
      if (!mounted || requested != _serviceId) return;
      if (_detail == null) setState(() => _error = error);
    }
  }

  void _switchTo(int serviceId) {
    if (serviceId == _serviceId) return;
    setState(() {
      _serviceId = serviceId;
      _detail = null;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final current = widget.siblings.where((s) => s.id == _serviceId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail?.name ?? current?.name ?? 'Service',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LafiaColors.ink),
            ),
            if (detail != null)
              Text(detail.hospitalName, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        shape: const Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (widget.siblings.length > 1)
                _ServiceChips(services: widget.siblings, selectedId: _serviceId, onSelected: _switchTo),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: detail != null
                    ? _Content(api: widget.api, detail: detail)
                    : _error != null
                        ? ErrorState(
                            error: _error!,
                            notFoundMessage: 'Ce service n\'existe pas ou n\'est plus en ligne.',
                            onRetry: () {
                              setState(() => _error = null);
                              _load();
                            },
                          )
                        : const LoadingState(label: 'Chargement du service…'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceChips extends StatelessWidget {
  const _ServiceChips({required this.services, required this.selectedId, required this.onSelected});

  final List<ServiceSummary> services;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final service = services[index];
          return ChoiceChipButton(
            label: service.name,
            icon: serviceIcon(service.name),
            selected: service.id == selectedId,
            onTap: () => onSelected(service.id),
          );
        },
      ),
    );
  }
}

/// Pastille de choix de la maquette : bleue si choisie, blanche sinon.
class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : LafiaColors.ink;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? LafiaColors.blue : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? LafiaColors.blue : LafiaColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.api, required this.detail});

  final HospitalsApi api;
  final ServiceDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Comme sur le site : la ligne des urgences de l'hôpital, en premier.
        if (detail.hospitalEmergencyPhone != null) ...[
          EmergencyCallCard(phone: detail.hospitalEmergencyPhone, hospitalName: detail.hospitalName),
          const SizedBox(height: 14),
        ],
        _Summary(detail: detail, onCall: () => api.recordServiceEvent(detail.id, ServiceEvent.call)),
        const SizedBox(height: 14),
        _WeekHours(detail: detail),
        if (detail.onCallShifts.isNotEmpty) ...[
          const SizedBox(height: 14),
          _OnCallShifts(shifts: detail.onCallShifts),
        ],
        const SizedBox(height: 14),
        _Doctors(detail: detail),
      ],
    );
  }
}

/// Carte du haut : statut du moment et appel direct du secrétariat.
class _Summary extends StatelessWidget {
  const _Summary({required this.detail, required this.onCall});

  final ServiceDetail detail;

  /// Appelé quand la personne lance l'appel (compteur du tableau de bord).
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final today = detail.hoursOn(dayOfWeek(nowInLome()));
    final phone = detail.phone;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceIconTile(serviceName: detail.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: LafiaColors.ink),
                    ),
                    Text(detail.hospitalName, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(status: detail.status),
                  const SizedBox(height: 6),
                  Text(
                    serviceHint(detail.status, today),
                    style: const TextStyle(fontSize: 12, color: LafiaColors.body),
                  ),
                ],
              ),
            ],
          ),
          if (detail.description != null && detail.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(detail.description!, style: const TextStyle(fontSize: 14, color: LafiaColors.body)),
          ],
          const SizedBox(height: 16),
          if (phone != null && phone.isNotEmpty) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: LafiaColors.green),
              onPressed: () => showCallSheet(
                context,
                title: 'Secrétariat, ${detail.name}',
                description: '${detail.hospitalName} : ligne directe du secrétariat du service '
                    '${detail.name}, sans passer par le standard.',
                phone: phone,
                onCall: onCall,
              ),
              icon: const Icon(Icons.phone_in_talk_outlined),
              label: const Text('Appel direct'),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'appel joint directement le secrétariat du service.',
              style: TextStyle(fontSize: 11),
            ),
          ] else
            const Text('Pas de ligne directe renseignée pour ce service.', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => runAsPatient(
              context,
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatScreen.service(
                    serviceId: detail.id,
                    serviceName: detail.name,
                    hospitalName: detail.hospitalName,
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Chat de pré-orientation'),
          ),
          // Pas d'horaires renseignés : aucun jour ne peut être proposé pour un rendez-vous.
          if (detail.hours.any((hour) => hour.range != null)) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => runAsPatient(context, () => showAppointmentSheet(context, detail)),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Demander un rendez-vous'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Horaires de la semaine en barres sur 24 h, avec l'heure actuelle (maquette M08).
class _WeekHours extends StatelessWidget {
  const _WeekHours({required this.detail});

  final ServiceDetail detail;

  @override
  Widget build(BuildContext context) {
    final now = nowInLome();
    final today = dayOfWeek(now);
    final nowMinutes = now.hour * 60 + now.minute;
    // Jours de la semaine à venir couverts par une garde.
    final onCallDays = {
      for (final shift in detail.onCallShifts)
        if (shift.date.difference(DateTime.utc(now.year, now.month, now.day)).inDays < 7) dayOfWeek(shift.date),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Horaires de la semaine', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 54, right: 96),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('0h', style: _axis), Text('12h', style: _axis), Text('24h', style: _axis)],
            ),
          ),
          const SizedBox(height: 4),
          for (final day in weekOrder)
            _DayRow(
              day: day,
              range: detail.hoursOn(day),
              isToday: day == today,
              nowMinutes: nowMinutes,
              onCall: onCallDays.contains(day),
            ),
          const SizedBox(height: 8),
          const Text(
            'Trait bleu : heure actuelle. Barre bleu clair : service de garde.',
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

const _axis = TextStyle(fontSize: 11, color: LafiaColors.muted);

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.range,
    required this.isToday,
    required this.nowMinutes,
    required this.onCall,
  });

  final int day;
  final TimeRange? range;
  final bool isToday;
  final int nowMinutes;
  final bool onCall;

  @override
  Widget build(BuildContext context) {
    final range = this.range;
    final label = range != null ? formatRange(range.start, range.end) : (onCall ? 'De garde' : 'Fermé');
    final showOnCall = range == null && onCall;

    return Semantics(
      label: '${dayName(day)}${isToday ? ' (aujourd\'hui)' : ''} : $label',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isToday ? LafiaColors.blueTint : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                shortDayName(day),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                  color: isToday ? LafiaColors.blueDeep : LafiaColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 18,
                child: CustomPaint(
                  painter: _BarPainter(
                    segments: range == null ? const [] : _segments(range),
                    onCall: showOnCall,
                    nowMinutes: isToday ? nowMinutes : null,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 88,
              child: Text(
                label,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: showOnCall ? FontWeight.w700 : FontWeight.w500,
                  color: showOnCall ? LafiaColors.blueDeep : LafiaColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Plages en minutes ; une plage de nuit (22h–6h) est coupée en deux.
  static List<(int, int)> _segments(TimeRange range) {
    if (isAllDay(range.start, range.end)) return const [(0, _minutesPerDay)];
    final start = minutesOf(range.start);
    final end = minutesOf(range.end);
    if (end > start) return [(start, end)];
    return [(start, _minutesPerDay), (0, end)];
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.segments, required this.onCall, required this.nowMinutes});

  final List<(int, int)> segments;
  final bool onCall;
  final int? nowMinutes;

  @override
  void paint(Canvas canvas, Size size) {
    const barHeight = 10.0;
    final top = (size.height - barHeight) / 2;
    const radius = Radius.circular(barHeight / 2);
    double x(int minutes) => size.width * minutes / _minutesPerDay;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, barHeight), radius),
      Paint()..color = LafiaColors.track,
    );

    if (onCall) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, barHeight), radius),
        Paint()..color = LafiaColors.blueTintBorder,
      );
    }

    final green = Paint()..color = LafiaColors.greenBar;
    for (final (start, end) in segments) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x(start), top, x(end), top + barHeight), radius),
        green,
      );
    }

    final now = nowMinutes;
    if (now != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x(now) - 1, 0, 2, size.height), const Radius.circular(1)),
        Paint()..color = LafiaColors.blueDark,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.onCall != onCall || oldDelegate.nowMinutes != nowMinutes;
}

class _OnCallShifts extends StatelessWidget {
  const _OnCallShifts({required this.shifts});

  final List<OnCallShift> shifts;

  static const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gardes à venir', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final shift in shifts.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${shortDayName(dayOfWeek(shift.date))} ${shift.date.day} ${_months[shift.date.month - 1]}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(formatRange(shift.range.start, shift.range.end), style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(width: 10),
                  Pill(label: shift.type == 'weekend' ? 'Week-end' : 'Garde', tone: PillTone.blue, dot: false),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Médecins du service, jour par jour (maquette M09).
class _Doctors extends StatefulWidget {
  const _Doctors({required this.detail});

  final ServiceDetail detail;

  @override
  State<_Doctors> createState() => _DoctorsState();
}

class _DoctorsState extends State<_Doctors> {
  late int _day = dayOfWeek(nowInLome());

  @override
  Widget build(BuildContext context) {
    final today = dayOfWeek(nowInLome());
    final isToday = _day == today;
    final doctors = widget.detail.doctors;
    final List<Doctor> visible;
    final String headline;

    if (isToday) {
      // Aujourd'hui : présents en ce moment d'abord, puis ceux attendus plus tard.
      final present = doctors.where((d) => d.currentStatus != null).toList();
      final later = doctors
          .where((d) => d.currentStatus == null && d.availabilities.any((a) => a.dayOfWeek == _day))
          .toList();
      visible = [...present, ...later];
      headline = present.isEmpty
          ? 'Aucun médecin présent en ce moment'
          : '${present.length} médecin${present.length > 1 ? 's' : ''} présent${present.length > 1 ? 's' : ''} en ce moment';
    } else {
      visible = doctors.where((d) => d.availabilities.any((a) => a.dayOfWeek == _day)).toList();
      headline = '${visible.length} médecin${visible.length > 1 ? 's' : ''} le ${dayName(_day).toLowerCase()}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Médecins et spécialistes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (doctors.isEmpty)
            const Text('Aucun médecin renseigné pour ce service.')
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in weekOrder)
                  ChoiceChipButton(
                    label: day == today ? '${shortDayName(day)} (aujourd\'hui)' : shortDayName(day),
                    selected: day == _day,
                    onTap: () => setState(() => _day = day),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(headline, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              const Text('Personne n\'est prévu ce jour-là. Appelez le secrétariat pour en savoir plus.')
            else
              for (final doctor in visible) ...[
                _DoctorCard(
                  doctor: doctor,
                  day: _day,
                  isHead: doctor.fullName == widget.detail.headName,
                  isToday: isToday,
                ),
                const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, required this.day, required this.isHead, required this.isToday});

  final Doctor doctor;
  final int day;
  final bool isHead;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final slots = doctor.availabilities.where((a) => a.dayOfWeek == day).toList();
    final onCall = isToday ? doctor.currentStatus == 'garde' : slots.any((a) => a.status == 'garde');
    final absentNow = isToday && doctor.currentStatus == null;

    final Pill pill;
    if (onCall) {
      pill = const Pill(label: 'De garde', tone: PillTone.blue, dot: false);
    } else if (absentNow) {
      pill = const Pill(label: 'Attendu plus tard', tone: PillTone.grey, dot: false);
    } else if (isHead) {
      pill = const Pill(label: 'Chef de service', dot: false);
    } else {
      pill = const Pill(label: 'En consultation', tone: PillTone.grey, dot: false);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LafiaColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: LafiaColors.blueSoft,
            child: Text(
              initials(doctor.fullName),
              style: const TextStyle(fontWeight: FontWeight.w700, color: LafiaColors.blueDeep),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    pill,
                    if (doctor.specialty != null)
                      Text(doctor.specialty!, style: const TextStyle(fontSize: 13, color: LafiaColors.body)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(scheduleSummary(doctor.availabilities), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « Lun–Ven 7h30–16h30 ; Sam 8h–12h » : jours regroupés par plage horaire identique.
String scheduleSummary(List<DoctorAvailability> slots) {
  final groups = <String, List<int>>{};
  for (final slot in slots) {
    groups.putIfAbsent(formatRange(slot.range.start, slot.range.end), () => []).add(slot.dayOfWeek);
  }

  return groups.entries.map((entry) {
    final days = weekOrder.where(entry.value.contains).toList();
    return '${_formatDays(days)} ${entry.key}';
  }).join(' ; ');
}

String _formatDays(List<int> days) {
  final positions = days.map(weekOrder.indexOf).toList();
  final consecutive = positions.length >= 3 && positions.last - positions.first == positions.length - 1;
  if (consecutive) return '${shortDayName(days.first)}–${shortDayName(days.last)}';
  return days.map(shortDayName).join(', ');
}
