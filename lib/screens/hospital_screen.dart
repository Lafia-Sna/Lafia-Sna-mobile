import 'dart:async';

import 'package:flutter/material.dart';

import '../api/hospitals_api.dart';
import '../api/models.dart';
import '../api/patient_api.dart' show ReviewTarget;
import '../format.dart';
import '../theme.dart';
import '../widgets/call_sheet.dart';
import '../widgets/emergency_call.dart';
import '../widgets/reviews_section.dart';
import '../widgets/service_icon.dart';
import '../widgets/states.dart';
import '../widgets/status_pill.dart';
import 'service_screen.dart';

// Le statut Ouvert / Fermé change dans la journée : on le rafraîchit chaque minute.
const _refreshEvery = Duration(minutes: 1);

/// Maquette M07 : fiche hôpital, vue d'ensemble des services.
class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key, required this.api, required this.hospitalId});

  final HospitalsApi api;
  final int hospitalId;

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  HospitalDetail? _detail;
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
    try {
      final detail = await widget.api.show(widget.hospitalId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = null;
      });
      widget.api.recordHospitalVisit(detail.hospital.id);
    } catch (error) {
      // Une erreur de rafraîchissement ne masque pas les informations déjà affichées.
      if (mounted && _detail == null) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: const Text(
          'Tous les hôpitaux',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LafiaColors.blueDark),
        ),
        shape: const Border(bottom: BorderSide(color: LafiaColors.divider)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LafiaGradients.page),
        child: detail != null
            ? RefreshIndicator(onRefresh: _load, child: _Content(api: widget.api, detail: detail))
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ErrorState(
                        error: _error!,
                        notFoundMessage: 'Cet hôpital n\'existe pas ou n\'est plus en ligne.',
                        onRetry: () {
                          setState(() => _error = null);
                          _load();
                        },
                      ),
                    ],
                  )
                : const LoadingState(label: 'Chargement de l\'hôpital…'),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.api, required this.detail});

  final HospitalsApi api;
  final HospitalDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Hero(detail: detail),
        if (detail.hospital.emergencyPhone != null) ...[
          const SizedBox(height: 12),
          EmergencyCallCard(phone: detail.hospital.emergencyPhone, hospitalName: detail.hospital.name),
        ],
        const SizedBox(height: 20),
        Text('Services', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (detail.services.isEmpty)
          const EmptyState(title: 'Aucun service renseigné pour cet hôpital.')
        else
          Container(
            decoration: cardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < detail.services.length; index++) ...[
                  if (index > 0) const Divider(height: 1, color: LafiaColors.greyTint),
                  _ServiceRow(
                    service: detail.services[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ServiceScreen(
                          api: api,
                          serviceId: detail.services[index].id,
                          siblings: detail.services,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        ReviewsSection(target: ReviewTarget.hospitals, id: detail.hospital.id, name: detail.hospital.name),
      ],
    );
  }
}

/// Bandeau dégradé : nom, adresse, appel du standard, itinéraire et résumé du moment.
class _Hero extends StatelessWidget {
  const _Hero({required this.detail});

  final HospitalDetail detail;

  @override
  Widget build(BuildContext context) {
    final hospital = detail.hospital;
    final services = detail.services;
    final open = services.where((s) => s.status == ServiceStatus.open).length;
    final onCall = services.where((s) => s.status == ServiceStatus.onCall).length;
    final closed = services.length - open - onCall;
    final now = nowInLome();
    final clock = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final address = [
      if (hospital.address != null && hospital.address!.isNotEmpty) hospital.address!,
      hospital.city,
      'région ${hospital.region}',
    ].join(', ');
    final phone = detail.phone;
    final latitude = hospital.latitude;
    final longitude = hospital.longitude;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LafiaGradients.hero,
        borderRadius: BorderRadius.circular(16),
        boxShadow: raisedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hospital.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 18, color: Color(0xFF82DCAB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address, style: const TextStyle(fontSize: 13, color: Color(0xE6FFFFFF))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (phone != null && phone.isNotEmpty)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: LafiaColors.blueDeep),
                    onPressed: () => showCallSheet(
                      context,
                      title: 'Standard, ${hospital.name}',
                      description: 'Accueil général de l\'hôpital.',
                      phone: phone,
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Standard'),
                  ),
                ),
              if (phone != null && phone.isNotEmpty && latitude != null && longitude != null)
                const SizedBox(width: 8),
              if (latitude != null && longitude != null)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0x26FFFFFF), foregroundColor: Colors.white),
                    onPressed: () => openDirections(latitude, longitude),
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Itinéraire'),
                  ),
                ),
            ],
          ),
          if (services.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              '${dayName(dayOfWeek(now))} $clock : $open ouvert${open > 1 ? 's' : ''}, '
              '$onCall de garde, $closed fermé${closed > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            SegmentedBar(
              filled: open,
              total: services.length,
              height: 8,
              filledColor: const Color(0xFF4AC487),
              emptyColor: const Color(0x40FFFFFF),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service, required this.onTap});

  final ServiceSummary service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            ServiceIconTile(serviceName: service.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(serviceHint(service.status, service.todayHours), style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(status: service.status),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

/// Précision sous le nom du service : « jusqu'à 16h30 », « ouvre à 8h »…
String serviceHint(ServiceStatus status, TimeRange? today) {
  switch (status) {
    case ServiceStatus.open:
      if (today == null) return 'ouvert maintenant';
      return isAllDay(today.start, today.end) ? '24h/24' : 'jusqu\'à ${formatTime(today.end)}';
    case ServiceStatus.onCall:
      return 'service de garde en cours';
    case ServiceStatus.closed:
      final now = nowInLome();
      if (today != null && now.hour * 60 + now.minute < minutesOf(today.start)) {
        return 'ouvre à ${formatTime(today.start)}';
      }
      return 'fermé pour aujourd\'hui';
  }
}
