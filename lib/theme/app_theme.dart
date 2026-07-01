// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF151C35);
  static const Color surface = Color(0xFF1C2448);
  static const Color headerBg = Color(0xFF1A2F6E);
  static const Color sheetBg = Color(0xFF1C2040);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color orange = Color(0xFFFF8C00);
  static const Color gold = Color(0xFFFFD600);
  static const Color teal = Color(0xFF00897B);
  static const Color textSecondary = Color(0xFF90CAF9);
  static const Color divider = Color(0x142D3A7A); // 8% white-blue

  static const List<Color> _accents = [
    Color(0xFFFFD600),
    Color(0xFF00E676),
    Color(0xFF64A0FF),
    Color(0xFFFF6B6B),
    Color(0xFFFF9F43),
    Color(0xFFA29BFE),
    Color(0xFF55EFC4),
    Color(0xFFFF7675),
  ];

  static Color accentFor(int id) => _accents[id % _accents.length];
}
