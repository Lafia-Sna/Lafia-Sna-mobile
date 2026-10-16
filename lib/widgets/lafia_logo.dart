import 'package:flutter/material.dart';

import '../theme.dart';

/// Logo officiel Lafia Sna, le même fichier que sur le site web.
class LafiaLogo extends StatelessWidget {
  const LafiaLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    // L'image (512 px) est décodée à la taille affichée : peu de mémoire sur les petits téléphones.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();

    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      cacheWidth: pixels,
      semanticLabel: 'Lafia Sna',
      filterQuality: FilterQuality.medium,
    );
  }
}

/// « Lafia » en bleu, « Sna » en vert.
class LafiaWordmark extends StatelessWidget {
  const LafiaWordmark({super.key, this.fontSize = 21});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Lafia ', style: style.copyWith(color: LafiaColors.blue)),
        TextSpan(text: 'Sna', style: style.copyWith(color: LafiaColors.green)),
      ]),
    );
  }
}
