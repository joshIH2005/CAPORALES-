import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Linea ornamental dorada con diamantes.
///
/// Se usa como divisor elegante en cabeceras, pies y secciones.
class OrnamentoDorado extends StatelessWidget {
  const OrnamentoDorado({
    super.key,
    this.ancho = 200,
    this.color = AppColors.gold,
  });

  final double ancho;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFFD4AF37)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          _diamante(relleno: false),
          const SizedBox(width: 7),
          _diamante(relleno: true),
          const SizedBox(width: 7),
          _diamante(relleno: false),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Color(0xFFD4AF37)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diamante({required bool relleno}) {
    final widget = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: relleno ? color : Colors.transparent,
        border: Border.all(
          color: color.withValues(alpha: relleno ? 1 : 0.7),
        ),
      ),
    );
    return Transform.rotate(angle: math.pi / 4, child: widget);
  }
}
