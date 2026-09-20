import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/api_config.dart';
import '../core/utils/formatters.dart';
import '../data/models/member_model.dart';
import '../data/models/record_model.dart';
import '../data/providers/api_service.dart';
import '../data/providers/local_store.dart';

/// Resultado de una operacion de cobro por QR.
class PagoResultado {
  final bool exitoso;
  final bool esDuplicado;
  final bool pendiente;
  final String mensaje;
  final Member? miembro;
  final Record? registro;

  const PagoResultado({
    required this.exitoso,
    this.esDuplicado = false,
    this.pendiente = false,
    required this.mensaje,
    this.miembro,
    this.registro,
  });
}

/// Resultado de un alta / edicion / anulacion de pago.
class ResultadoOperacion {
  final bool ok;
  final bool pendiente;
  final String mensaje;

  const ResultadoOperacion({
    required this.ok,
    this.pendiente = false,
    required this.mensaje,
  });
}

/// Controlador principal de la aplicacion (ChangeNotifier).
///
/// Gestiona el estado global: integrantes, registros, configuración local,
/// la cola de escrituras pendientes (modo offline) y metricas.
class MemberController extends ChangeNotifier {
  MemberController({ApiService? api, LocalStore? store})
      : _api = api ?? ApiService(),
        _store = store ?? LocalStore();

  final ApiService _api;
  final LocalStore _store;

  // ===== Estado global =====
  List<Member> _members = [];
  List<Record> _records = [];
  List<OpPendiente> _cola = [];

  bool _loading = false;
  bool _offline = false;
  String? _error;
  bool _inicializado = false;

  double _montoEnsayo = ApiConfig.aporteEnsayo;
  int _diasCriticos = ApiConfig.diasCriticos;

  // ===== Getters publicos =====
  List<Member> get members => List.unmodifiable(_members);
  List<Record> get records => List.unmodifiable(_records);
  bool get loading => _loading;
  bool get offline => _offline;
  String? get error => _error;
  double get montoEnsayo => _montoEnsayo;
  int get diasCriticos => _diasCriticos;
  int get pendientes => _cola.length;

  /// Total recaudado en soles (suma de montos de registro).
  double get totalRecaudado => _records.fold(0, (sum, r) => sum + r.monto);

  /// Recaudado del mes en curso.
  double get recaudadoDelMes {
    final clave = Formatters.claveMes(DateTime.now());
    return _records
        .where((r) =>
            Formatters.claveMes(
                Formatters.parsearFecha(r.fecha) ?? DateTime(2020, 1, 1)) ==
            clave)
        .fold(0, (sum, r) => sum + r.monto);
  }

  /// Recaudado del mes anterior.
  double get recaudadoMesAnterior {
    final ahora = DateTime.now();
    final anterior = DateTime(ahora.year, ahora.month - 1, 1);
    final clave = Formatters.claveMes(anterior);
    return _records
        .where((r) =>
            Formatters.claveMes(
                Formatters.parsearFecha(r.fecha) ?? DateTime(2020, 1, 1)) ==
            clave)
        .fold(0, (sum, r) => sum + r.monto);
  }

  /// Total de integrantes activos.
  int get totalIntegrantes => _members.length;

  /// Total de pagos registrados.
  int get totalPagos => _records.length;

  /// Integrante con mas asistencias (top del mes en curso).
  (String nombre, int asistencias)? get mejorAsistente {
    final clave = Formatters.claveMes(DateTime.now());
    final counts = <String, int>{};
    for (final r in _records) {
      if (Formatters.claveMes(
              Formatters.parsearFecha(r.fecha) ?? DateTime(2020, 1, 1)) !=
          clave) {
        continue;
      }
      counts[r.memberId] = (counts[r.memberId] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    String mejorId = '';
    var mejor = 0;
    counts.forEach((id, n) {
      if (n > mejor) {
        mejor = n;
        mejorId = id;
      }
    });
    final miembro = _members.where((m) => m.id == mejorId).firstOrNull;
    if (miembro == null) return null;
    return (miembro.nombresApellidos, mejor);
  }

  /// Integrantes con inasistencias criticas (+N dias sin registro).
  List<Member> get inasistenciasCriticas {
    final corte = DateTime.now().subtract(
      Duration(days: _diasCriticos),
    );

    return _members.where((miembro) {
      // Busca el ultimo registro del integrante.
      final registros = _records.where((r) => r.memberId == miembro.id).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

      if (registros.isEmpty) return true; // Nunca asistio -> critico.

      final ultima = Formatters.parsearFecha(registros.first.fecha);
      return ultima == null || ultima.isBefore(corte);
    }).toList();
  }

  /// Cuenta los dias sin asistencia de un integrante (null si nunca asistio).
  int? diasSinAsistencia(String memberId) {
    final registros = _records.where((r) => r.memberId == memberId).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    if (registros.isEmpty) return null;

    final ultima = Formatters.parsearFecha(registros.first.fecha);
    if (ultima == null) return 0;

    return DateTime.now().difference(ultima).inDays;
  }

  /// Registros de un integrante ordenados del mas reciente al mas antiguo.
  List<Record> registrosDe(String memberId) {
    final lista = _records.where((r) => r.memberId == memberId).toList()
      ..sort((a, b) {
        final cmp = b.fecha.compareTo(a.fecha);
        if (cmp != 0) return cmp;
        return b.hora.compareTo(a.hora);
      });
    return List.unmodifiable(lista);
  }

  /// Indica si un miembro tiene una operacion (alta/edicion) pendiente.
  bool miembroPendiente(String id) => _cola.any((op) =>
      (op.tipo == OpPendiente.tipoNuevoMiembro ||
          op.tipo == OpPendiente.tipoActualizarMiembro) &&
      op.id == id);

  /// Indica si un registro tiene una operacion (pago/anulacion) pendiente.
  bool registroPendiente(String id) => _cola.any((op) =>
      (op.tipo == OpPendiente.tipoRegistrarPago ||
          op.tipo == OpPendiente.tipoEliminarRegistro) &&
      op.id == id);

  /// Total recaudado por mes: {"2026-09": 12.0, ...}.
  Map<String, double> recaudadoPorMes() {
    final porMes = <String, double>{};
    for (final r in _records) {
      final fecha = Formatters.parsearFecha(r.fecha);
      if (fecha == null) continue;
      final clave = Formatters.claveMes(fecha);
      porMes[clave] = (porMes[clave] ?? 0) + r.monto;
    }
    return porMes;
  }

  // ===== Inicializacion y sincronizacion =====

  /// Carga configuracion local, cola de pendientes y cache (una sola vez).
  Future<void> inicializar() async {
    _montoEnsayo = await _store.leerMontoEnsayo();
    _diasCriticos = await _store.leerDiasCriticos();
    _cola = await _store.leerCola();
    _inicializado = true;
    notifyListeners();
  }

  /// Descarga datos desde la API (o cache si no hay conexion) y recalcula.
  Future<void> cargarDatos() async {
    if (!_inicializado) await inicializar();

    _loading = true;
    notifyListeners();

    try {
      // 1. Reintenta las escrituras pendientes.
      await _sincronizarPendientes();

      // 2. Descarga el estado real del servidor.
      final datos = await _api.obtenerDatos();
      var base = (members: datos.members, records: datos.records);
      base = _aplicarCola(base.members, base.records);

      _members = base.members;
      _records = base.records;
      _offline = false;
      _error = null;
      await _store.guardarSnapshot(_members, _records);
    } catch (e) {
      debugPrint('cargarDatos (offline): $e');
      final cache = await _store.cargarSnapshot();
      if (cache != null) {
        var base = _aplicarCola(cache.members, cache.records);
        _members = base.members;
        _records = base.records;
      }
      _offline = true;
      _error =
          cache == null ? 'No se pudo sincronizar con Google Sheets.' : null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Reenvia las operaciones pendientes al servidor (en orden).
  Future<int> _sincronizarPendientes() async {
    if (_cola.isEmpty) return 0;
    var sincronizados = 0;

    for (final op in List.of(_cola)) {
      try {
        switch (op.tipo) {
          case OpPendiente.tipoNuevoMiembro:
          case OpPendiente.tipoActualizarMiembro:
            final res = op.tipo == OpPendiente.tipoNuevoMiembro
                ? await _api.crearMiembro(Member.fromMap(op.datos))
                : await _api.actualizarMiembro(Member.fromMap(op.datos));
            if (!res.ok) throw Exception(res.error ?? 'ok:false');
            break;
          case OpPendiente.tipoRegistrarPago:
            final res = await _api.registrarPago(Record.fromMap(op.datos));
            if (!res.ok) throw Exception(res.error ?? 'ok:false');
            break;
          case OpPendiente.tipoEliminarRegistro:
            final res = await _api.anularRegistro(op.id);
            if (!res.ok) throw Exception(res.error ?? 'ok:false');
            break;
        }
        _cola.removeWhere((e) => e.id == op.id);
        sincronizados++;
      } catch (e) {
        debugPrint('sincronizarPendientes detenido: $e');
        break; // Detiene la cola (orden)
      }
    }

    if (sincronizados > 0) {
      await _store.reemplazarCola(_cola);
      notifyListeners();
    }
    return sincronizados;
  }

  /// Aplica las operaciones pendientes sobre un conjunto base de datos.
  ({List<Member> members, List<Record> records}) _aplicarCola(
    List<Member> members,
    List<Record> records,
  ) {
    final resultado = (
      members: List<Member>.of(members),
      records: List<Record>.of(records),
    );

    for (final op in _cola) {
      switch (op.tipo) {
        case OpPendiente.tipoNuevoMiembro:
        case OpPendiente.tipoActualizarMiembro:
          final miembro = Member.fromMap(op.datos);
          final idx = resultado.members.indexWhere((m) => m.id == miembro.id);
          if (idx >= 0) {
            resultado.members[idx] = miembro;
          } else {
            resultado.members.add(miembro);
          }
          break;
        case OpPendiente.tipoRegistrarPago:
          final registro = Record.fromMap(op.datos);
          if (!resultado.records.any((r) => r.id == registro.id)) {
            resultado.records.add(registro);
          }
          break;
        case OpPendiente.tipoEliminarRegistro:
          resultado.records.removeWhere((r) => r.id == op.id);
          break;
      }
    }
    return resultado;
  }

  /// Sincroniza pendientes y refresca los datos (boton de sincronizar).
  Future<void> sincronizarTodo() => cargarDatos();

  // ===== Acciones: cobros =====

  /// Registra el pago/asistencia de un integrante identificado por QR
  /// o por seleccion manual. Si [forzar] es true, ignora el duplicado del dia.
  Future<PagoResultado> registrarPagoPorId(
    String memberId, {
    bool forzar = false,
  }) async {
    final index = _members.indexWhere((m) => m.id == memberId);

    if (index < 0) {
      return const PagoResultado(
        exitoso: false,
        mensaje: 'Integrante no encontrado. Verifique el codigo QR.',
      );
    }

    final miembro = _members[index];
    final now = DateTime.now();
    final hoy = Formatters.hoyISO();

    // Proteccion contra doble cobro el mismo dia.
    final yaPagoHoy = _records.any(
      (r) => r.memberId == miembro.id && r.fecha == hoy && r.asistencia,
    );

    if (yaPagoHoy && !forzar) {
      return PagoResultado(
        exitoso: false,
        esDuplicado: true,
        mensaje: 'Este integrante ya registró su aporte hoy '
            '(${Formatters.soles(_montoEnsayo)}). ¿Registrar de todos modos?',
        miembro: miembro,
      );
    }

    final registro = Record(
      id: '$memberId-${now.millisecondsSinceEpoch}',
      memberId: miembro.id,
      memberName: miembro.nombresApellidos,
      fecha: hoy,
      hora: Formatters.horaCorta(now),
      monto: _montoEnsayo,
      asistencia: true,
    );

    // 1. Registro local + cola (sirve aunque no haya conexion).
    final op = OpPendiente(
      tipo: OpPendiente.tipoRegistrarPago,
      datos: registro.toMap(),
      id: registro.id,
      creado: now,
    );
    _cola.add(op);
    await _store.encolar(op);
    _records.add(registro);
    notifyListeners();

    // 2. Intenta enviar; si falla queda pendiente para sincronizar.
    try {
      final res = await _api.registrarPago(registro);
      if (res.ok) {
        _cola.removeWhere((e) => e.id == op.id);
        await _store.quitarDeCola(op.id);
        notifyListeners();
        return PagoResultado(
          exitoso: true,
          mensaje: 'Pago registrado correctamente',
          miembro: miembro,
          registro: registro,
        );
      }
      // El servidor rechazo: quita de la cola y notifica.
      _cola.removeWhere((e) => e.id == op.id);
      await _store.quitarDeCola(op.id);
      notifyListeners();
      return PagoResultado(
        exitoso: false,
        mensaje:
            'El servidor no confirmó el registro: ${res.error ?? 'sin detalle'}',
        miembro: miembro,
      );
    } catch (e) {
      debugPrint('registrarPagoPorId (offline): $e');
      return PagoResultado(
        exitoso: true,
        pendiente: true,
        mensaje: 'Pago registrado (pendiente de sincronizar)',
        miembro: miembro,
        registro: registro,
      );
    }
  }

  // ===== Acciones: integrantes =====

  /// Crea un nuevo integrante. Genera su ID y lo envia a la API.
  Future<(bool ok, String mensaje, Member? creado)> crearMiembro({
    required String nombresApellidos,
    required int edad,
    required String fechaNacimiento,
    required String ocupacion,
    String telefono = '',
  }) async {
    final miembro = Member(
      id: Formatters.generarIdMiembro(),
      nombresApellidos: nombresApellidos,
      edad: edad,
      fechaNacimiento: fechaNacimiento,
      ocupacion: ocupacion,
      estado: 'Activo',
      fechaIngreso: Formatters.hoyISO(),
      telefono: telefono.trim(),
    );

    final op = OpPendiente(
      tipo: OpPendiente.tipoNuevoMiembro,
      datos: miembro.toMap(),
      id: miembro.id,
      creado: DateTime.now(),
    );
    _cola.add(op);
    await _store.encolar(op);
    _members.add(miembro);
    notifyListeners();

    try {
      final res = await _api.crearMiembro(miembro);
      if (!res.ok) {
        _cola.removeWhere((e) => e.id == op.id);
        await _store.quitarDeCola(op.id);
        _members.removeWhere((m) => m.id == miembro.id);
        notifyListeners();
        return (
          false,
          'El servidor no confirmó el alta: ${res.error ?? 'sin detalle'}',
          null,
        );
      }
      _cola.removeWhere((e) => e.id == op.id);
      await _store.quitarDeCola(op.id);
      notifyListeners();
      return (true, 'Integrante registrado', miembro);
    } catch (e) {
      debugPrint('crearMiembro (offline): $e');
      return (
        true,
        'Integrante registrado (pendiente de sincronizar)',
        miembro
      );
    }
  }

  /// Actualiza los datos de un integrante existente.
  Future<ResultadoOperacion> actualizarMiembro(Member miembro) async {
    final idx = _members.indexWhere((m) => m.id == miembro.id);
    if (idx < 0) {
      return const ResultadoOperacion(
          ok: false, mensaje: 'Integrante no encontrado');
    }

    // Actualiza tambien el nombre en sus registros (referencias).
    _members[idx] = miembro;
    for (var i = 0; i < _records.length; i++) {
      if (_records[i].memberId == miembro.id) {
        _records[i] = Record(
          id: _records[i].id,
          memberId: _records[i].memberId,
          memberName: miembro.nombresApellidos,
          fecha: _records[i].fecha,
          hora: _records[i].hora,
          monto: _records[i].monto,
          asistencia: _records[i].asistencia,
        );
      }
    }

    final op = OpPendiente(
      tipo: OpPendiente.tipoActualizarMiembro,
      datos: miembro.toMap(),
      id: miembro.id,
      creado: DateTime.now(),
    );
    _cola.add(op);
    await _store.encolar(op);
    notifyListeners();

    try {
      final res = await _api.actualizarMiembro(miembro);
      if (!res.ok) {
        _cola.removeWhere((e) => e.id == op.id);
        await _store.quitarDeCola(op.id);
        notifyListeners();
        return ResultadoOperacion(
          ok: false,
          mensaje:
              'El servidor no confirmó la edición: ${res.error ?? 'sin detalle'}',
        );
      }
      _cola.removeWhere((e) => e.id == op.id);
      await _store.quitarDeCola(op.id);
      notifyListeners();
      return const ResultadoOperacion(
          ok: true, mensaje: 'Integrante actualizado');
    } catch (e) {
      debugPrint('actualizarMiembro (offline): $e');
      return const ResultadoOperacion(
        ok: true,
        pendiente: true,
        mensaje: 'Cambios guardados (pendiente de sincronizar)',
      );
    }
  }

  // ===== Acciones: anular pago =====

  /// Anula (revierte) un registro de pago.
  Future<ResultadoOperacion> anularPago(Record registro) async {
    if (_records.every((r) => r.id != registro.id)) {
      return const ResultadoOperacion(
          ok: false, mensaje: 'Registro no encontrado');
    }

    _records.removeWhere((r) => r.id == registro.id);
    notifyListeners();

    final op = OpPendiente(
      tipo: OpPendiente.tipoEliminarRegistro,
      datos: {'id': registro.id},
      id: registro.id,
      creado: DateTime.now(),
    );
    _cola.add(op);
    await _store.encolar(op);

    try {
      final res = await _api.anularRegistro(registro.id);
      if (!res.ok) {
        _cola.removeWhere((e) => e.id == op.id);
        await _store.quitarDeCola(op.id);
        // Vuelve a aparecer el registro localmente.
        _records.add(registro);
        notifyListeners();
        return ResultadoOperacion(
          ok: false,
          mensaje:
              'El servidor no confirmó la anulación: ${res.error ?? 'sin detalle'}',
        );
      }
      _cola.removeWhere((e) => e.id == op.id);
      await _store.quitarDeCola(op.id);
      notifyListeners();
      return const ResultadoOperacion(ok: true, mensaje: 'Pago anulado');
    } catch (e) {
      debugPrint('anularPago (offline): $e');
      // El registro ya no está en la lista local; queda la orden pendiente.
      notifyListeners();
      return const ResultadoOperacion(
        ok: true,
        pendiente: true,
        mensaje: 'Pago anulado (pendiente de sincronizar)',
      );
    }
  }

  // ===== Acciones: configuracion =====

  /// Cambia el monto del aporte por ensayo.
  Future<void> setMontoEnsayo(double monto) async {
    _montoEnsayo = monto;
    await _store.guardarMontoEnsayo(monto);
    notifyListeners();
  }

  /// Cambia el umbral de dias para considerar "critico".
  Future<void> setDiasCriticos(int dias) async {
    _diasCriticos = dias;
    await _store.guardarDiasCriticos(dias);
    notifyListeners();
  }
}
