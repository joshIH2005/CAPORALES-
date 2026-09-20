import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../logic/member_controller.dart';
import '../widgets/logo_medallon.dart';
import '../widgets/ornamento_dorado.dart';
import 'add_member_screen.dart';
import 'dashboard_screen.dart';
import 'scanner_screen.dart';

/// Pagina principal: logotipo del elenco, resumen de metricas y
/// los tres accesos rapidos (Dashboard, Escaner QR, Nuevo integrante).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final MemberController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Se difiere al post-frame: cargarDatos() notifica al controller
    // sincrónicamente y no se puede notificar durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.cargarDatos();
    });
  }

  Future<void> _recargar() async {
    await widget.controller.cargarDatos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos sincronizados')),
      );
    }
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => pantalla),
    );
  }

  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final controller = widget.controller;
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  // ===== Cabecera con boton de sincronizacion =====
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Sincronizar',
                      onPressed: controller.loading ? null : _recargar,
                      icon: controller.loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.gold,
                              ),
                            )
                          : const Icon(
                              Icons.sync,
                              color: AppColors.goldLight,
                            ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // ===== Identidad con el logotipo =====
                  const LogoMedallon(tamano: 142, sombra: true),
                  const SizedBox(height: 20),

                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.gold.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'NOBLEZA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.red.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'CAPORAL',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const OrnamentoDorado(ancho: 200),
                  const SizedBox(height: 12),

                  Text(
                    '$_saludo · Elenco de danza',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ===== Resumen de metricas =====
                  _filaMetricas(controller),
                  const SizedBox(height: 28),

                  // ===== Titulo del menu =====
                  Text(
                    'M E N Ú   P R I N C I P A L',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle(context).copyWith(
                      fontSize: 13,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Accesos rapidos =====
                  if (controller.error != null && controller.members.isEmpty)
                    _avisoSinConexion(controller.error!,
                        onReintentar: _recargar)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 16),

                  _MenuOpcion(
                    icono: Icons.dashboard_rounded,
                    titulo: 'Dashboard',
                    descripcion: 'Integrantes, pagos y asistencias',
                    acento: AppColors.gold,
                    gradienteIcono: AppGradients.gold,
                    onTap: () =>
                        _abrir(DashboardScreen(controller: widget.controller)),
                  ),
                  const SizedBox(height: 14),
                  _MenuOpcion(
                    icono: Icons.qr_code_scanner,
                    titulo: 'Escaner QR',
                    descripcion: 'Registrar aporte con la cámara',
                    acento: AppColors.red,
                    gradienteIcono: AppGradients.red,
                    onTap: () =>
                        _abrir(ScannerScreen(controller: widget.controller)),
                  ),
                  const SizedBox(height: 14),
                  _MenuOpcion(
                    icono: Icons.person_add_alt_1,
                    titulo: 'Nuevo integrante',
                    descripcion: 'Alta y carnet digital',
                    acento: AppColors.goldLight,
                    gradienteIcono: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.goldLight, AppColors.red],
                    ),
                    onTap: () =>
                        _abrir(AddMemberScreen(controller: widget.controller)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _filaMetricas(MemberController controller) {
    return Row(
      children: [
        Expanded(
          child: _StatMini(
            icono: Icons.attach_money,
            valor: Formatters.soles(controller.totalRecaudado),
            etiqueta: 'Recaudado',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMini(
            icono: Icons.groups,
            valor: '${controller.totalIntegrantes}',
            etiqueta: 'Integrantes',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatMini(
            icono: Icons.receipt_long,
            valor: '${controller.totalPagos}',
            etiqueta: 'Pagos',
            color: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }

  Widget _avisoSinConexion(String mensaje,
      {required VoidCallback onReintentar}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.warning, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta compacta de metrica para la pagina principal.
class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icono, color: color, size: 19),
          ),
          const Spacer(),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta grande de acceso rapido con icono degradado.
class _MenuOpcion extends StatelessWidget {
  const _MenuOpcion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.acento,
    required this.gradienteIcono,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color acento;
  final LinearGradient gradienteIcono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                acento.withValues(alpha: 0.22),
                AppColors.card,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: acento.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradienteIcono,
                  boxShadow: [
                    BoxShadow(
                      color: acento.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icono, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.gold,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
