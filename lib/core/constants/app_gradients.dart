import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Degradados reutilizables de la aplicacion.
class AppGradients {
  AppGradients._();

  /// Fondo general de las pantallas (negro profundo con leva profundidad).
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF171717), AppColors.background, AppColors.background],
  );

  /// Dorado noble: cabeceras, acentos y detalles premium.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
  );

  /// Rojo pasion: botones CTA e identidad del elenco.
  static const LinearGradient red = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0455F), AppColors.red, AppColors.redDark],
  );

  /// Boton primario por defecto (Rojo Pasion = llamada a la accion).
  static const LinearGradient primary = red;

  /// Superficie de tarjetas (gris oscuro sutil).
  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF202020), AppColors.card],
  );

  /// Degradado segun color base (para estados de exito/error).
  static LinearGradient state(Color base) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(base, Colors.white, 0.18)!,
          Color.lerp(base, Colors.black, 0.32)!,
        ],
      );
}
