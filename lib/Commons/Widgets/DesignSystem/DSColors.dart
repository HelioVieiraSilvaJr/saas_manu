import 'package:flutter/material.dart';

/// Design System - Paleta de cores centralizada.
///
/// NUNCA usar cores hardcoded. Sempre referenciar DSColors().
class DSColors {
  // MARK: Primary
  Color get primaryColor => const Color(0xFF6366F1); // Indigo
  Color get primaryLight => const Color(0xFF818CF8);
  Color get primaryDark => const Color(0xFF4F46E5);

  // MARK: Secondary
  Color get secundaryColor => const Color(0xFF8B5CF6); // Purple
  Color get secundaryLight => const Color(0xFFA78BFA);
  Color get secundaryDark => const Color(0xFF7C3AED);

  // MARK: Accent / Highlights
  Color get tint => const Color(0xFF6366F1);
  Color get highlights => const Color(0xFFF59E0B); // Amber

  // MARK: Backgrounds
  Color get background => const Color(0xFFF8FAFC);
  Color get surfaceColor => const Color(0xFFFFFFFF);
  Color get cardBackground => const Color(0xFFFFFFFF);
  Color get scaffoldBackground => const Color(0xFFF1F5F9);

  // MARK: Neutral
  Color get white => const Color(0xFFFFFFFF);
  Color get black => const Color(0xFF0F172A);
  Color get grey => const Color(0xFF64748B);
  Color get greyLight => const Color(0xFF94A3B8);
  Color get greyLighter => const Color(0xFFCBD5E1);
  Color get greyLightest => const Color(0xFFE2E8F0);
  Color get divider => const Color(0xFFE2E8F0);

  // MARK: Semantic / Status
  Color get red => const Color(0xFFEF4444);
  Color get redLight => const Color(0xFFFEE2E2);
  Color get green => const Color(0xFF10B981);
  Color get greenLight => const Color(0xFFD1FAE5);
  Color get yellow => const Color(0xFFF59E0B);
  Color get yellowLight => const Color(0xFFFEF3C7);
  Color get blue => const Color(0xFF3B82F6);
  Color get blueLight => const Color(0xFFDBEAFE);
  Color get orange => const Color(0xFFF97316);
  Color get orangeLight => const Color(0xFFFED7AA);

  // MARK: WhatsApp
  Color get whatsappGreen => const Color(0xFF25D366);

  // MARK: Text
  Color get textPrimary => const Color(0xFF0F172A);
  Color get textSecondary => const Color(0xFF475569);
  Color get textTertiary => const Color(0xFF94A3B8);
  Color get textOnPrimary => const Color(0xFFFFFFFF);
  Color get textLink => const Color(0xFF6366F1);

  // MARK: Input
  Color get inputBorder => const Color(0xFFCBD5E1);
  Color get inputBorderFocused => const Color(0xFF6366F1);
  Color get inputBackground => const Color(0xFFFFFFFF);
  Color get inputError => const Color(0xFFEF4444);

  // MARK: Shadow
  Color get shadowColor => const Color(0x0A000000);
}
