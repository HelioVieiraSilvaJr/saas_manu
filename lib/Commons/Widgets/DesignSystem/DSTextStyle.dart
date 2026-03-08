import 'package:flutter/material.dart';
import 'DSColors.dart';

/// Design System - Estilos de texto padronizados.
///
/// NUNCA usar TextStyle hardcoded. Sempre referenciar DSTextStyle().
class DSTextStyle {
  final DSColors _colors = DSColors();

  // MARK: Headlines
  TextStyle get headline1 => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: _colors.textPrimary,
    height: 1.2,
  );

  TextStyle get headline2 => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _colors.textPrimary,
    height: 1.3,
  );

  TextStyle get headline3 => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _colors.textPrimary,
    height: 1.3,
  );

  // Alias usado no ARCHITECTURE.md
  TextStyle get headline => headline2;

  // MARK: Body
  TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _colors.textPrimary,
    height: 1.5,
  );

  TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.textPrimary,
    height: 1.5,
  );

  TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.textSecondary,
    height: 1.5,
  );

  // MARK: Labels
  TextStyle get labelLarge => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _colors.textPrimary,
    height: 1.4,
  );

  TextStyle get labelMedium => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _colors.textSecondary,
    height: 1.4,
  );

  TextStyle get labelSmall => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: _colors.textTertiary,
    height: 1.4,
  );

  // MARK: Specialized
  TextStyle get textField => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.textPrimary,
    height: 1.5,
  );

  TextStyle get textFieldLabel => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _colors.textSecondary,
    height: 1.4,
  );

  TextStyle get textFieldHint => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _colors.textTertiary,
    height: 1.5,
  );

  TextStyle get textFieldError => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.red,
    height: 1.4,
  );

  TextStyle get menuItem => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _colors.textPrimary,
    height: 1.4,
  );

  TextStyle get button =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _colors.textTertiary,
    height: 1.4,
  );

  TextStyle get price => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _colors.primaryColor,
    height: 1.3,
  );

  TextStyle get metricValue => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _colors.textPrimary,
    height: 1.2,
  );

  TextStyle get metricComparison =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);
}
