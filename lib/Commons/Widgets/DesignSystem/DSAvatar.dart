import 'dart:math';
import 'package:flutter/material.dart';

/// Design System - Avatar circular com iniciais geradas automaticamente.
class DSAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  final double? fontSize;

  const DSAvatar({
    super.key,
    required this.name,
    required this.size,
    this.imageUrl,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
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
  }

  /// Gera iniciais a partir do nome.
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  /// Gera cor consistente baseada no hash do nome.
  Color _getColorFromName(String name) {
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFFF59E0B), // Amber
      Color(0xFF10B981), // Green
      Color(0xFF3B82F6), // Blue
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF97316), // Orange
      Color(0xFF14B8A6), // Teal
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
