import 'package:flutter/material.dart';

class CategoryColors {
  static const List<Color> palette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFF84CC16), // Lime
    Color(0xFF3B82F6), // Blue
    Color(0xFFD946EF), // Fuchsia
  ];

  static Color getColor(String category) {
    if (category == 'Other' || category == 'Add') return Colors.grey;

    // Simple hash to get a consistent color for the same string
    int hash = 0;
    for (int i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return palette[hash.abs() % palette.length];
  }
}
