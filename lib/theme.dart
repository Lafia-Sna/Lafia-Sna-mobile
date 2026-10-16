import 'package:flutter/material.dart';

/// Couleurs de la maquette Figma (identiques au logo et au site web).
abstract final class LafiaColors {
  static const blue = Color(0xFF0A66CC);
  static const blueDark = Color(0xFF0A52A6);
  static const blueDeep = Color(0xFF0D4584);
  static const navy = Color(0xFF10396B);
  static const blueTint = Color(0xFFEEF6FF);
  static const blueTintBorder = Color(0xFFBCDCFF);
  static const blueSoft = Color(0xFFD9EBFF);

  static const green = Color(0xFF0F9A55);
  static const greenBar = Color(0xFF22A96A);
  static const greenInk = Color(0xFF0E623A);
  static const greenTint = Color(0xFFEFFCF4);
  static const greenTintBorder = Color(0xFFB4EDCB);

  static const ink = Color(0xFF12263F);
  static const body = Color(0xFF334155);
  static const muted = Color(0xFF475569);
  static const subtle = Color(0xFF64748B);
  static const border = Color(0xFFCBD5E1);
  static const cardBorder = Color(0xFFD6E2F0);
  static const divider = Color(0xFFE2E8F0);
  static const track = Color(0xFFE2E8F0);
  static const greyTint = Color(0xFFF1F5F9);

  static const backgroundTop = Color(0xFFE6F0FA);
  static const background = Color(0xFFF3F7FB);
}

/// Dégradés de la maquette.
abstract final class LafiaGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LafiaColors.navy, LafiaColors.blueDeep, LafiaColors.blue],
  );

  static const tile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [LafiaColors.blueDark, Color(0xFF2F84F0)],
  );

  static const page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [LafiaColors.backgroundTop, LafiaColors.background],
  );
}

const cardShadow = [BoxShadow(color: Color(0x1410396B), blurRadius: 3, offset: Offset(0, 1))];
const raisedShadow = [BoxShadow(color: Color(0x2110396B), blurRadius: 18, offset: Offset(0, 6))];

/// Carte blanche à bord bleuté, utilisée partout dans la maquette.
BoxDecoration cardDecoration({Color borderColor = LafiaColors.cardBorder, double borderWidth = 1}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor, width: borderWidth),
    boxShadow: cardShadow,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LafiaColors.blue,
    primary: LafiaColors.blue,
    secondary: LafiaColors.green,
    surface: Colors.white,
    onSurface: LafiaColors.ink,
  );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  return ThemeData(
    // Police de la maquette Figma
    fontFamily: 'Figtree',
    colorScheme: scheme,
    scaffoldBackgroundColor: LafiaColors.background,
    // Cibles tactiles d'au moins 48 px
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: LafiaColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48), textStyle: buttonText, shape: buttonShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: buttonText,
        shape: buttonShape,
        foregroundColor: LafiaColors.ink,
        side: const BorderSide(color: LafiaColors.border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: buttonText,
        foregroundColor: LafiaColors.blueDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: LafiaColors.subtle, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LafiaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LafiaColors.blue, width: 2),
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: LafiaColors.ink),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LafiaColors.ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LafiaColors.ink),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: LafiaColors.ink),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: LafiaColors.muted),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LafiaColors.muted),
    ),
  );
}
