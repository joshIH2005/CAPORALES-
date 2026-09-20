import 'package:flutter/material.dart';

import '../../core/constants/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/member_model.dart';
import '../../logic/member_controller.dart';
import '../widgets/metric_card.dart';

/// Dashboard: metricas (recaudado, integrantes, pagos) y
/// lista roja de inasistencias criticas (+14 dias).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.controller});

  final MemberController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
  }

  /// Saludo segun la hora del dia.
  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  /// Fecha larga en espanol, ej: "viernes, 19 de septiembre".
  String get _fechaLarga {
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final now = DateTime.now();
    return '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';
  }

  /// Dias sin asistencia del integrante (null si nunca asistio).
  int? _diasSinAsistencia(MemberController controller, Member m) {
    final registros = controller.records
        .where((r) => r.memberId == m.id)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    if (registros.isEmpty) return null;

    final ultima = DateTime.tryParse(registros.first.fecha);
    if (ultima == null) return 0;

    return DateTime.now().difference(ultima).inDays;
  }

  /// Integrantes ordenados alfabeticamente para la lista completa.
  List<Member> _miembrosOrdenados(MemberController controller) {
    final lista = [...controller.members];
    lista.sort((a, b) => a.nombresApellidos.toLowerCase().compareTo(
          b.nombresApellidos.toLowerCase(),
        ));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Dashboard'),
        // ===== Logotipo pequeño en la barra =====
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: ClipOval(
            child: Image.asset(
              'imagenes/foto_nobleza.jpeg',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sincronizar',
            onPressed: _recargar,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.loading && controller.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null && controller.members.isEmpty) {
            return _ErrorView(mensaje: controller.error!, onRetry: _recargar);
          }

          final criticos = controller.inasistenciasCriticas;

          return RefreshIndicator(
            onRefresh: _recargar,
            edgeOffset: 90,
            backgroundColor: AppColors.surfaceAlt,
            color: AppColors.primaryLight,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ===== Tarjeta de bienvenida =====
                _WelcomeCard(
                  saludo: _saludo,
                  fecha: _fechaLarga,
                  totalIntegrantes: controller.totalIntegrantes,
                ),
                const SizedBox(height: 20),

                // ===== Fila de metricas =====
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        icon: Icons.attach_money,
                        label: 'Total recaudado',
                        value: Formatters.soles(controller.totalRecaudado),
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        icon: Icons.groups,
                        label: 'Integrantes',
                        value: '${controller.totalIntegrantes}',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        icon: Icons.receipt_long,
                        label: 'Pagos registrados',
                        value: '${controller.totalPagos}',
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'Criticos (+${ApiConfig.diasCriticos}d)',
                        value: '${criticos.length}',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ===== Titulo seccion integrantes y pagos =====
                Row(
                  children: [
                    const Icon(Icons.groups,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Integrantes y pagos',
                        style: AppTextStyles.subtitle(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '${controller.members.length}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (controller.members.isEmpty)
                  const _EmptyMembers()
                else
                  ..._miembrosOrdenados(controller).map((m) {
                    final registrosCompra = controller.records
                        .where((r) => r.memberId == m.id)
                        .toList();
                    final totalPagado = registrosCompra.fold<double>(
                        0, (sum, r) => sum + r.monto);
                    final asistencias =
                        registrosCompra.where((r) => r.asistencia).length;
                    return _MemberTile(
                      member: m,
                      totalPagado: totalPagado,
                      asistencias: asistencias,
                    );
                  }),

                const SizedBox(height: 28),

                // ===== Titulo seccion inasistencias =====
                Row(
                  children: [
                    const Icon(Icons.monitor_heart_outlined,
                        color: AppColors.error, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Inasistencias criticas',
                      style: AppTextStyles.subtitle(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (criticos.isEmpty)
                  const _EmptyState()
                else
                  ...criticos.map(
                    (m) => _CriticalTile(
                      member: m,
                      dias: _diasSinAsistencia(controller, m),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta de bienvenida con degradado de marca.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.saludo,
    required this.fecha,
    required this.totalIntegrantes,
  });

  final String saludo;
  final String fecha;
  final int totalIntegrantes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saludo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fecha,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '$totalIntegrantes integrantes en el elenco',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ===== Logotipo del elenco =====
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'imagenes/foto_nobleza.jpeg',
                width: 74,
                height: 74,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista de error con boton de reintento.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onRetry});

  final String mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacio cuando no hay integrantes registrados.
class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aún no hay integrantes registrados.',
              style: AppTextStyles.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de un integrante con su total pagado y asistencias.
class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.totalPagado,
    required this.asistencias,
  });

  final Member member;
  final double totalPagado;
  final int asistencias;

  String get _iniciales {
    final partes = member.nombresApellidos
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textoAsistencias =
        '$asistencias ${asistencias == 1 ? 'asistencia' : 'asistencias'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar de iniciales con fondo dorado
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.gold,
            ),
            child: Text(
              _iniciales,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.nombresApellidos,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${member.id}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.soles(totalPagado),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                textoAsistencias,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estado vacio cuando no hay inasistencias criticas.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.success, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todos los integrantes están al día. ¡Excelente!',
              style: AppTextStyles.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta roja de un integrante con inasistencia critica.
class _CriticalTile extends StatelessWidget {
  const _CriticalTile({required this.member, this.dias});

  final Member member;
  final int? dias;

  @override
  Widget build(BuildContext context) {
    final subtitulo =
        dias == null ? 'Nunca ha asistido' : 'Sin asistencia hace $dias días';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.error.withValues(alpha: 0.18),
          child: const Icon(Icons.person_off, color: AppColors.error),
        ),
        title: Text(
          member.nombresApellidos,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'ID: ${member.id}  •  $subtitulo',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'CRITICO',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
