import 'dart:math';
import 'package:flutter/material.dart';
import 'DSColors.dart';

/// Design System v2.0 — Avatar circular com iniciais USE3D.
class DSAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  final double? fontSize;
  final bool showBorder;
  final Color? statusColor;

  const DSAvatar({
    super.key,
    required this.name,
    required this.size,
    this.imageUrl,
    this.fontSize,
    this.showBorder = false,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: _getColorFromName(name),
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              _getInitials(name),
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? size / 2.5,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    Widget result = showBorder
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: avatar,
          )
        : avatar;

    if (statusColor != null) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          result,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    return result;
  }

  /// Gera iniciais a partir do nome.
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  /// Gera cor consistente baseada no hash do nome — paleta USE3D v2.0.
  Color _getColorFromName(String name) {
    const colors = [
      Color(0xFF1E3A5F), // Navy (primary)
      Color(0xFF0D9488), // Teal (secondary)
      Color(0xFFF59E0B), // Amber (accent)
      Color(0xFF2D5F8A), // Primary Light
      Color(0xFF059669), // Green
      Color(0xFF2563EB), // Blue
      Color(0xFFDC2626), // Red
      Color(0xFF0F766E), // Teal Dark
      Color(0xFFF97316), // Orange
      Color(0xFF8B5CF6), // Purple
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
