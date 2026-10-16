import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme.dart';

enum PillTone { green, blue, grey, amber, red }

/// Pastille arrondie de la maquette : « Ouvert », « De garde », « 5/7 services ouverts »…
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.tone = PillTone.green, this.dot = true, this.icon});

  final String label;
  final PillTone tone;
  final bool dot;

  /// Icône à la place du point (ex. repère pour une distance).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, border, ink) = switch (tone) {
      PillTone.green => (LafiaColors.greenTint, LafiaColors.greenTintBorder, LafiaColors.greenInk),
      PillTone.blue => (LafiaColors.blueTint, LafiaColors.blueTintBorder, LafiaColors.blueDeep),
      PillTone.grey => (LafiaColors.greyTint, LafiaColors.divider, LafiaColors.body),
      PillTone.amber => (const Color(0xFFFFFBEB), const Color(0xFFFDE68A), const Color(0xFF92400E)),
      PillTone.red => (const Color(0xFFFEF2F2), const Color(0xFFFECACA), const Color(0xFFB91C1C)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: ink),
            const SizedBox(width: 4),
          ] else if (dot) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: ink, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ServiceStatus.open => const Pill(label: 'Ouvert'),
      ServiceStatus.onCall => const Pill(label: 'De garde', tone: PillTone.blue),
      ServiceStatus.closed => const Pill(label: 'Fermé', tone: PillTone.grey),
    };
  }
}

/// Barre découpée en segments : un segment vert par service ouvert.
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    super.key,
    required this.filled,
    required this.total,
    this.height = 6,
    this.filledColor = LafiaColors.greenBar,
    this.emptyColor = LafiaColors.border,
  });

  final int filled;
  final int total;
  final double height;
  final Color filledColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return SizedBox(height: height);

    return ExcludeSemantics(
      child: Row(
        children: [
          for (var index = 0; index < total; index++) ...[
            if (index > 0) const SizedBox(width: 2),
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: index < filled ? filledColor : emptyColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// État d'un rendez-vous ou d'une demande de soins (mêmes libellés que le site web).
class RequestStatusPill extends StatelessWidget {
  const RequestStatusPill({super.key, required this.status, this.feminine = false});

  /// `pending` | `confirmed` | `accepted` | `done` | `declined` | `cancelled`
  final String status;

  /// « Refusée », « Annulée » pour une demande ; « Refusé », « Annulé » pour un rendez-vous.
  final bool feminine;

  @override
  Widget build(BuildContext context) {
    final e = feminine ? 'e' : '';
    final (label, tone) = switch (status) {
      'pending' => ('En attente de réponse', PillTone.amber),
      'confirmed' => ('Rendez-vous confirmé', PillTone.green),
      'accepted' => ('Acceptée', PillTone.green),
      'done' => ('Terminée', PillTone.blue),
      'declined' => ('Refusé$e', PillTone.red),
      _ => ('Annulé$e', PillTone.grey),
    };
    return Pill(label: label, tone: tone);
  }
}
