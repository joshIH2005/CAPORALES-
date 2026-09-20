import 'package:flutter/material.dart';

/// Paleta de colores "Nobleza Caporal": negro profundo,
/// dorado noble y rojo pasion (identidad del elenco).
class AppColors {
  AppColors._();

  // ===== Colores de marca =====
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE9C766);
  static const Color goldDark = Color(0xFFA8862B);
  static const Color red = Color(0xFFC41E3A);
  static const Color redDark = Color(0xFF8F1430);
  static const Color seed = gold;

  // ===== Alias semanticos (para los widgets existentes) =====
  static const Color primary = gold; // Acentos / iconos / destacados
  static const Color primaryLight = goldLight;
  static const Color primaryDark = goldDark;
  static const Color secondary = red; // Elementos de accion del elenco

  // ===== Fondos / superficies (Negro profundo) =====
  static const Color background = Color(0xFF0C0C0C);
  static const Color surface = Color(0xFF151515);
  static const Color surfaceAlt = Color(0xFF212121);
  static const Color card = Color(0xFF181818);

  // ===== Texto =====
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBDBDBD);

  // ===== Bordes suaves =====
  static const Color border = Color(0xFF3A3A3A);

  // ===== Estados =====
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFC41E3A);
  static const Color warning = Color(0xFFD4AF37);
}
