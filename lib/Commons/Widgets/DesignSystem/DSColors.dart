import 'package:flutter/material.dart';

/// Design System v2.0 — Paleta de cores USE3D.
///
/// NUNCA usar cores hardcoded. Sempre referenciar DSColors().
class DSColors {
  // ══════════════════════════════════════════════
  // PRIMARY — Azul Profundo (confiança, profissionalismo)
  // ══════════════════════════════════════════════
  final Color primaryColor = const Color(0xFF1E3A5F);
  final Color primaryLight = const Color(0xFF2D5F8A);
  final Color primaryDark = const Color(0xFF0F2440);
  final Color primarySurface = const Color(0xFFE8EFF7);

  // ══════════════════════════════════════════════
  // SECONDARY — Teal Vibrante (ação, energia)
  // ══════════════════════════════════════════════
  final Color secundaryColor = const Color(0xFF0D9488);
  final Color secundaryLight = const Color(0xFF2DD4BF);
  final Color secundaryDark = const Color(0xFF0F766E);
  final Color secundarySurface = const Color(0xFFE6F7F5);

  // ══════════════════════════════════════════════
  // ACCENT — Âmbar Quente (destaques, CTAs especiais)
  // ══════════════════════════════════════════════
  final Color tint = const Color(0xFF1E3A5F);
  final Color highlights = const Color(0xFFF59E0B);
  final Color accentWarm = const Color(0xFFE67E22);

  // ══════════════════════════════════════════════
  // BACKGROUNDS — Sistema de Camadas (Elevation)
  // ══════════════════════════════════════════════
  final Color background = const Color(0xFFF7F9FC);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color cardBackground = const Color(0xFFFFFFFF);
  final Color scaffoldBackground = const Color(0xFFF0F4F8);
  final Color surfaceElevated = const Color(0xFFFFFFFF);
  final Color surfaceOverlay = const Color(0xFFF8FAFD);

  // ══════════════════════════════════════════════
  // NEUTRAL — Escala de Cinzas Frios
  // ══════════════════════════════════════════════
  final Color white = const Color(0xFFFFFFFF);
  final Color black = const Color(0xFF0B1929);
  final Color grey = const Color(0xFF5A6B7F);
  final Color greyLight = const Color(0xFF8696A7);
  final Color greyLighter = const Color(0xFFBCC8D4);
  final Color greyLightest = const Color(0xFFDDE4ED);
  final Color divider = const Color(0xFFE3E9F0);

  // ══════════════════════════════════════════════
  // SEMANTIC — Estados do Sistema
  // ══════════════════════════════════════════════
  final Color red = const Color(0xFFDC2626);
  final Color redLight = const Color(0xFFFEE2E2);
  final Color green = const Color(0xFF059669);
  final Color greenLight = const Color(0xFFD1FAE5);
  final Color yellow = const Color(0xFFF59E0B);
  final Color yellowLight = const Color(0xFFFEF3C7);
  final Color blue = const Color(0xFF2563EB);
  final Color blueLight = const Color(0xFFDBEAFE);
  final Color orange = const Color(0xFFF97316);
  final Color orangeLight = const Color(0xFFFED7AA);

  // ══════════════════════════════════════════════
  // WHATSAPP
  // ══════════════════════════════════════════════
  final Color whatsappGreen = const Color(0xFF25D366);

  // ══════════════════════════════════════════════
  // TEXT — Hierarquia de Leitura
  // ══════════════════════════════════════════════
  final Color textPrimary = const Color(0xFF0B1929);
  final Color textSecondary = const Color(0xFF3D4F63);
  final Color textTertiary = const Color(0xFF8696A7);
  final Color textOnPrimary = const Color(0xFFFFFFFF);
  final Color textOnSecondary = const Color(0xFFFFFFFF);
  final Color textLink = const Color(0xFF1E3A5F);

  // ══════════════════════════════════════════════
  // INPUT — Campos de Formulário
  // ══════════════════════════════════════════════
  final Color inputBorder = const Color(0xFFBCC8D4);
  final Color inputBorderFocused = const Color(0xFF1E3A5F);
  final Color inputBackground = const Color(0xFFFFFFFF);
  final Color inputError = const Color(0xFFDC2626);
  final Color inputSuccess = const Color(0xFF059669);

  // ══════════════════════════════════════════════
  // SHADOW — Sistema de Elevação
  // ══════════════════════════════════════════════
  final Color shadowColor = const Color(0x0F0B1929);
  final Color shadowMedium = const Color(0x1A0B1929);
  final Color shadowStrong = const Color(0x290B1929);

  // ══════════════════════════════════════════════
  // GRADIENTES
  // ══════════════════════════════════════════════
  LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF2D5F8A)],
  );

  LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
  );

  LinearGradient get warmGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFE67E22)],
  );
}
