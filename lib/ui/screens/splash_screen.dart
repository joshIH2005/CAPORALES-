import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../logic/member_controller.dart';
import '../widgets/ornamento_dorado.dart';
import 'home_screen.dart';

/// Pantalla de inicio "Nobleza Caporal": fondo negro inmersivo con brillo
/// dorado, logotipo del elenco en un medallon ornamentado con anillos de
/// rayos rotantes, titulares en degradado dorado/rojo y detalles elegantes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

  final MemberController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrada;
  late final AnimationController _rotacion;
  late final AnimationController _pulso;
  late final Animation<double> _opacidad;
  late final Animation<double> _escala;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();

    _opacidad = CurvedAnimation(
      parent: _entrada,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _escala = CurvedAnimation(
      parent: _entrada,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
    );

    _rotacion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _timer = Timer(const Duration(milliseconds: 4200), _irAlMenu);
  }

  void _irAlMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(controller: widget.controller),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrada.dispose();
    _rotacion.dispose();
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== Fondo: negro profundo con destellos de marca =====
          const _FondoNoble(),

          // ===== Ornamento superior e inferior =====
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 56),
              child: OrnamentoDorado(ancho: 240),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _opacidad,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 56),
                child: _PieSplash(),
              ),
            ),
          ),

          // ===== Contenido central =====
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: FadeTransition(
                opacity: _opacidad,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== Medallon del logotipo =====
                    ScaleTransition(
                      scale: _escala,
                      child: _LogoBadge(
                        rotacion: _rotacion,
                        pulso: _pulso,
                      ),
                    ),
                    const SizedBox(height: 42),

                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradients.gold.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'NOBLEZA',
                        style: GoogleFonts.cinzel(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12,
                          height: 1.05,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // ===== Titular rojo del elenco =====
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradients.red.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'CAPO RAL',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    const OrnamentoDorado(ancho: 170),
                    const SizedBox(height: 18),

                    Text(
                      'ELENCO DE DANZA',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo negro con brillos radiales: dorado en el centro y vino en los extremos.
class _FondoNoble extends StatelessWidget {
  const _FondoNoble();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
          colors: [
            Color(0xFF160E08),
            AppColors.background,
            Color(0xFF1C0A10),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Brillo dorado detras del medallon
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x33D4AF37),
                    Color(0x00D4AF37),
                  ],
                  stops: [0.25, 1.0],
                ),
              ),
            ),
          ),
          // Resplandor rojo en la base
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 500,
              height: 240,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  colors: [
                    Color(0x2EC41E3A),
                    Color(0x00C41E3A),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Medallon circular del logotipo con anillo de rayos dorados rotando.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.rotacion, required this.pulso});

  final Animation<double> rotacion;
  final Animation<double> pulso;

  @override
  Widget build(BuildContext context) {
    final halo = ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: pulso, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 250,
        height: 250,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color(0x66D4AF37),
              Color(0x00D4AF37),
            ],
            stops: [0.5, 1.0],
          ),
        ),
      ),
    );

    final rayos = AnimatedBuilder(
      animation: rotacion,
      child: const CustomPaint(
        size: Size(250, 250),
        painter: _SunburstPainter(),
      ),
      builder: (context, child) => Transform.rotate(
        angle: rotacion.value * 2 * math.pi,
        child: child,
      ),
    );

    final medallon = Container(
      width: 208,
      height: 208,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.gold,
        boxShadow: [
          BoxShadow(
            color: Color(0x80D4AF37),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: ClipOval(
          child: Image.asset(
            'imagenes/foto_nobleza.jpeg',
            width: 190,
            height: 190,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [halo, rayos, medallon],
      ),
    );
  }
}

/// Rayos cortos alrededor del medallon (sol en homenaje al Caporal).
class _SunburstPainter extends CustomPainter {
  const _SunburstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radio = size.shortestSide / 2;

    final trazoLargo = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.95)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final trazoCorto = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const n = 64;
    for (var i = 0; i < n; i++) {
      final angulo = i * (2 * math.pi / n);
      final largo = i.isEven ? 13.0 : 6.0;
      final p1 = Offset(
        center.dx + math.cos(angulo) * (radio - 15 - largo),
        center.dy + math.sin(angulo) * (radio - 15 - largo),
      );
      final p2 = Offset(
        center.dx + math.cos(angulo) * (radio - 14),
        center.dy + math.sin(angulo) * (radio - 14),
      );
      canvas.drawLine(p1, p2, i.isEven ? trazoLargo : trazoCorto);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) => false;
}

/// Pie de pantalla: ornamentos, anio en numeros romanos y puntos animados.
class _PieSplash extends StatelessWidget {
  const _PieSplash();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const OrnamentoDorado(ancho: 150),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (bounds) => AppGradients.gold.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'MMXXV',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _PuntosAnimados(),
      ],
    );
  }
}

/// Tres puntos dorados que laten al ritmo del pulso.
class _PuntosAnimados extends StatefulWidget {
  @override
  State<_PuntosAnimados> createState() => _PuntosAnimadosState();
}

class _PuntosAnimadosState extends State<_PuntosAnimados>
    with SingleTickerProviderStateMixin {
  late final AnimationController _punto;

  @override
  void initState() {
    super.initState();
    _punto = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _punto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _punto,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final fase = (_punto.value + i * 0.33) * math.pi;
            final opacidad = (math.sin(fase)).abs().clamp(0.25, 1.0).toDouble();
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: opacidad),
              ),
            );
          }),
        );
      },
    );
  }
}
