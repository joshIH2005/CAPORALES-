import 'package:flutter/material.dart';

import '../../core/constants/app_gradients.dart';

/// Boton con fondo degradado, borde redondeado y efecto ripple.
///
/// Soporta estado de carga (spinner) y deshabilitado automatico.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.gradient = AppGradients.primary,
    this.loading = false,
    this.height = 52,
    this.textStyle,
  });

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final LinearGradient gradient;
  final bool loading;
  final double height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(16);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        if (label != null)
                          Text(
                            label!,
                            style: textStyle ??
                                const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
