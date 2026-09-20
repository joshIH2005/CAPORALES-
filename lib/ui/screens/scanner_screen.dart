import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/qr_firma.dart';
import '../../logic/member_controller.dart';
import '../widgets/avatar_miembro.dart';
import '../widgets/gradient_button.dart';

/// Pantalla de escaner QR con camara.
///
/// Al detectar un codigo: detiene la camara, registra el pago y
/// muestra un ModalBottomSheet con el resultado (verde/rojo).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.controller});

  final MemberController controller;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _procesando = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Procesa el QR detectado: valida la firma y registra el pago.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;

    final qr =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (qr == null || qr.isEmpty) return;

    _procesando = true;
    await _scannerController.stop(); // Detiene la camara

    // Anti-falsificacion: solo acepta QRs firmados con el HMAC interno.
    final id = QrFirma.validar(qr);
    if (id == null) {
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isDismissible: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ResultadoSheet(
          resultado: const PagoResultado(
            exitoso: false,
            mensaje: 'Carnet inválido o desactualizado. '
                'Pide que compartan el carnet nuevamente desde la app.',
          ),
          onCerrar: _reiniciarEscaneo,
        ),
      );
      return;
    }

    final resultado = await widget.controller.registrarPagoPorId(id);
    if (!mounted) return;

    // Muestra el resultado elegante.
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultadoSheet(
        resultado: resultado,
        onCerrar: _reiniciarEscaneo,
      ),
    );
  }

  /// Reanuda la camara tras cerrar el modal.
  Future<void> _reiniciarEscaneo() async {
    _procesando = false;
    if (mounted) {
      await _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Escanear QR'),
      ),
      body: Stack(
        children: [
          // ===== Camara =====
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // ===== Overlay con marco de escaneo =====
          const _ScannerOverlay(),

          // ===== Texto de ayuda inferior =====
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Enfoca el QR del carnet digital',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marco cuadrado con esquinas y linea de escaneo animada.
class _ScannerOverlay extends StatefulWidget {
  const _ScannerOverlay();

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => CustomPaint(
          painter: _ScannerFramePainter(_animation.value),
        ),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.72;
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2 - 20;
    final rect = Rect.fromLTWH(left, top, side, side);

    // Oscurece el area fuera del marco.
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), dimPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, top + side, size.width, size.height - top - side),
      dimPaint,
    );
    canvas.drawRect(Rect.fromLTWH(0, top, left, side), dimPaint);
    canvas.drawRect(
      Rect.fromLTWH(left + side, top, size.width - left - side, side),
      dimPaint,
    );

    // Esquinas moradas (en degradado).
    final esquina = side * 0.2;
    final esquinaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryLight, AppColors.primaryDark],
      ).createShader(rect)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Superior izquierda
    canvas.drawLine(
        rect.topLeft, Offset(rect.left + esquina, rect.top), esquinaPaint);
    canvas.drawLine(
        rect.topLeft, Offset(rect.left, rect.top + esquina), esquinaPaint);
    // Superior derecha
    canvas.drawLine(
        rect.topRight, Offset(rect.right - esquina, rect.top), esquinaPaint);
    canvas.drawLine(
        rect.topRight, Offset(rect.right, rect.top + esquina), esquinaPaint);
    // Inferior izquierda
    canvas.drawLine(rect.bottomLeft, Offset(rect.left + esquina, rect.bottom),
        esquinaPaint);
    canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - esquina),
        esquinaPaint);
    // Inferior derecha
    canvas.drawLine(rect.bottomRight, Offset(rect.right - esquina, rect.bottom),
        esquinaPaint);
    canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - esquina),
        esquinaPaint);

    // Linea de escaneo animada (barrido vertical).
    final lineaY = top + side * (0.15 + progress * 0.7);
    final lineaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primaryLight,
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(left, lineaY, side, 3));
    canvas.drawRect(
      Rect.fromLTWH(left + 14, lineaY, side - 28, 3),
      lineaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Modal elegante con el resultado del escaneo.
class _ResultadoSheet extends StatelessWidget {
  const _ResultadoSheet({required this.resultado, required this.onCerrar});

  final PagoResultado resultado;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final ok = resultado.exitoso;
    final color = ok ? AppColors.success : AppColors.error;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== Icono de estado (animado) =====
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  ok ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 56,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Titulo =====
            Text(
              ok ? '¡Pago registrado!' : 'Error',
              style: ok
                  ? AppTextStyles.headline(context)
                  : AppTextStyles.headline(context).copyWith(
                      color: AppColors.error,
                    ),
            ),
            const SizedBox(height: 6),

            Text(
              resultado.mensaje,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context),
            ),

            if (resultado.miembro != null) ...[
              const SizedBox(height: 20),
              // ===== Datos del integrante =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    AvatarMiembro(member: resultado.miembro!, radius: 30),
                    const SizedBox(height: 10),
                    Text(
                      resultado.miembro!.nombreUpper,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle(context),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ID: ${resultado.miembro!.id}',
                      style: AppTextStyles.label(context),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: ok
                                ? AppColors.success.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            ok
                                ? 'Aporte: ${Formatters.soles(resultado.registro?.monto ?? 0)}'
                                : 'Pago no realizado',
                            style: TextStyle(
                              color: ok
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ===== Botón continuar =====
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: onCerrar,
                label: 'Continuar',
                gradient: AppGradients.state(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
