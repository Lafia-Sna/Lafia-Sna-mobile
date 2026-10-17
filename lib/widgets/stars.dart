import 'package:flutter/material.dart';

import '../api/patient_api.dart';
import '../theme.dart';

const starColor = Color(0xFFF59E0B);

/// Étoiles pleines, demi et vides pour une note de 0 à 5.
class Stars extends StatelessWidget {
  const Stars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              rating >= i
                  ? Icons.star_rounded
                  : rating >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: size,
              color: starColor,
            ),
        ],
      ),
    );
  }
}

/// « ★ 4,5 (12 avis) » ; « Nouveau » quand il n'y a pas encore d'avis.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.average, required this.count, this.likes = 0});

  RatingBadge.from(RatingSummary summary, {super.key})
      : average = summary.average,
        count = summary.reviewsCount,
        likes = summary.likesCount;

  final double? average;
  final int count;
  final int likes;

  @override
  Widget build(BuildContext context) {
    final average = this.average;
    if (average == null || count == 0) {
      return const Text('Pas encore d\'avis', style: TextStyle(fontSize: 12));
    }

    final value = average.toStringAsFixed(1).replaceAll('.', ',');
    return Semantics(
      label: 'Note $value sur 5, $count avis${likes > 0 ? ', $likes j\'aime' : ''}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: starColor),
          const SizedBox(width: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LafiaColors.ink)),
          Text(' ($count avis)', style: const TextStyle(fontSize: 12)),
          if (likes > 0) ...[
            const SizedBox(width: 8),
            const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFE11D48)),
            const SizedBox(width: 2),
            Text('$likes', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// Choix d'une note de 1 à 5 étoiles (boutons tactiles larges).
class StarInput extends StatelessWidget {
  const StarInput({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _labels = ['Très mauvais', 'Mauvais', 'Correct', 'Bien', 'Excellent'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i étoile${i > 1 ? 's' : ''} : ${_labels[i - 1]}',
            isSelected: value >= i,
            onPressed: () => onChanged(i),
            icon: Icon(
              value >= i ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 34,
              color: starColor,
            ),
          ),
      ],
    );
  }
}
