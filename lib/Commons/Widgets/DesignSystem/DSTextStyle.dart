import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'DSColors.dart';

/// Design System v2.0 — Tipografia USE3D (DM Sans).
///
/// NUNCA usar TextStyle hardcoded. Sempre referenciar DSTextStyle().
class DSTextStyle {
  final DSColors _colors = DSColors();

  // ══════════════════════════════════════════════
  // DISPLAY — Números grandes, hero sections
  // ══════════════════════════════════════════════
  TextStyle get displayLarge => GoogleFonts.dmSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: _colors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );

  // ══════════════════════════════════════════════
  // HEADLINES — Títulos de página e seção
  // ══════════════════════════════════════════════
  TextStyle get headline1 => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _colors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  TextStyle get headline2 => GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: _colors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  TextStyle get headline3 => GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: _colors.textPrimary,
    height: 1.3,
  );

  TextStyle get headline => headline2;

  // ══════════════════════════════════════════════
  // BODY — Corpo de texto
  // ══════════════════════════════════════════════
  TextStyle get bodyLarge => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _colors.textPrimary,
    height: 1.6,
  );

  TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.textPrimary,
    height: 1.5,
  );

  TextStyle get bodySmall => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.textSecondary,
    height: 1.5,
  );

  // ══════════════════════════════════════════════
  // LABELS — Elementos de UI
  // ══════════════════════════════════════════════
  TextStyle get labelLarge => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _colors.textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  TextStyle get labelMedium => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _colors.textSecondary,
    height: 1.4,
  );

  TextStyle get labelSmall => GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: _colors.textTertiary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ══════════════════════════════════════════════
  // FORM — Campos de formulário
  // ══════════════════════════════════════════════
  TextStyle get textField => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.textPrimary,
    height: 1.5,
  );

  TextStyle get textFieldLabel => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _colors.textSecondary,
    height: 1.4,
  );

  TextStyle get textFieldHint => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.textTertiary,
    height: 1.5,
  );

  TextStyle get textFieldError => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.red,
  );

  // ══════════════════════════════════════════════
  // ESPECIAIS
  // ══════════════════════════════════════════════
  TextStyle get button => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _colors.textPrimary,
    height: 1.4,
    letterSpacing: 0.2,
  );

  TextStyle get caption => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.textTertiary,
  );

  TextStyle get menuItem => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _colors.textPrimary,
  );

  TextStyle get price => GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _colors.primaryColor,
  );

  TextStyle get metricValue => GoogleFonts.dmSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  TextStyle get metricComparison =>
      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500);

  // NOVO — Overline para headers de seção
  TextStyle get overline => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _colors.textTertiary,
    height: 1.4,
    letterSpacing: 1.2,
  );
}
