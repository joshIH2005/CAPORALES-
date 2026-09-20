import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos de texto reutilizables.
///
/// Titulos y cabeceras: Cinzel (serif elegante) en Dorado Noble.
/// Cuerpo de texto: Poppins (sans-serif moderna) en Blanco Puro.
class AppTextStyles {
  AppTextStyles._();

  /// Titulo principal de pantalla (dorado, elegante).
  static TextStyle headline(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
      );

  /// Subtitulo de seccion (dorado).
  static TextStyle subtitle(BuildContext context) => GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.gold,
      );

  /// Texto de cuerpo normal (blanco puro atenuado).
  static TextStyle body(BuildContext context) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Valor numerico grande (metricas del dashboard).
  static TextStyle metricValue(BuildContext context) => GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  /// Texto de etiqueta (labels y chips).
  static TextStyle label(BuildContext context) => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Nombre en el carnet digital (mayusculas).
  static TextStyle carnetName(BuildContext context) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  /// ID en el carnet digital.
  static TextStyle carnetId(BuildContext context) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      );
}
