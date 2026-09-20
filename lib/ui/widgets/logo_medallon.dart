import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';

/// Medallon circular con el logotipo del elenco y doble anillo dorado.
class LogoMedallon extends StatelessWidget {
  const LogoMedallon({super.key, this.tamano = 132, this.sombra = false});

  final double tamano;
  final bool sombra;

  @override
  Widget build(BuildContext context) {
    const factorAnilloExterior = 0.03;
    const factorAnilloInterior = 0.025;
    final ladoFoto = tamano * 0.88;

    return Container(
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * factorAnilloExterior),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.gold,
        boxShadow: sombra
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Container(
        padding: EdgeInsets.all(tamano * factorAnilloInterior),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: ClipOval(
          child: Image.asset(
            'imagenes/foto_nobleza.jpeg',
            width: ladoFoto,
            height: ladoFoto,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
