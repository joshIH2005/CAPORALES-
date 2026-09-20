import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_config.dart';
import '../models/member_model.dart';
import '../models/record_model.dart';

/// Operacion pendiente de sincronizar con el backend (cola offline).
class OpPendiente {
  final String tipo;
  final Map<String, dynamic> datos;
  final String id;
  final DateTime creado;

  const OpPendiente({
    required this.tipo,
    required this.datos,
    required this.id,
    required this.creado,
  });

  Map<String, dynamic> toMap() => {
        'tipo': tipo,
        'datos': datos,
        'id': id,
        'creado': creado.toIso8601String(),
      };

  static OpPendiente? fromMap(Map<String, dynamic> map) {
    final tipo = map['tipo']?.toString();
    final datos = map['datos'];
    final id = map['id']?.toString();
    if (tipo == null || id == null || datos is! Map) return null;
    return OpPendiente(
      tipo: tipo,
      datos: Map<String, dynamic>.from(datos),
      id: id,
      creado:
          DateTime.tryParse(map['creado']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static const tipoNuevoMiembro = 'nuevo_miembro';
  static const tipoActualizarMiembro = 'actualizar_miembro';
  static const tipoRegistrarPago = 'registrar_pago';
  static const tipoEliminarRegistro = 'eliminar_registro';
}

/// Persistencia local: cache de datos (modo offline) + cola de escrituras
/// pendientes + configuracion del usuario (monto, dias criticos).
class LocalStore {
  static const _kSnapshot = 'cache_snapshot_v2';
  static const _kCola = 'cola_pendientes_v2';
  static const _kMonto = 'cfg_monto_ensayo';
  static const _kCriticos = 'cfg_dias_criticos';

  // ===== Snapshot (cache offline) =====

  Future<({List<Member> members, List<Record> records})?>
      cargarSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSnapshot);
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final members = (json['members'] as List<dynamic>? ?? [])
          .map((e) => Member.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      final records = (json['records'] as List<dynamic>? ?? [])
          .map((e) => Record.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      return (members: members, records: records);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarSnapshot(
    List<Member> members,
    List<Record> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSnapshot,
      jsonEncode({
        'members': members.map((m) => m.toMap()).toList(),
        'records': records.map((r) => r.toMap()).toList(),
      }),
    );
  }

  // ===== Cola de operaciones pendientes =====

  Future<List<OpPendiente>> leerCola() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCola);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OpPendiente.fromMap(Map<String, dynamic>.from(e as Map)))
          .whereType<OpPendiente>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _guardarCola(List<OpPendiente> cola) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCola,
      jsonEncode(cola.map((op) => op.toMap()).toList()),
    );
  }

  Future<void> encolar(OpPendiente op) async {
    final cola = await leerCola();
    cola.add(op);
    await _guardarCola(cola);
  }

  Future<void> quitarDeCola(String id) async {
    final cola = await leerCola();
    cola.removeWhere((op) => op.id == id);
    await _guardarCola(cola);
  }

  Future<void> reemplazarCola(List<OpPendiente> cola) async {
    await _guardarCola(cola);
  }

  // ===== Configuracion =====

  Future<double> leerMontoEnsayo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kMonto) ?? ApiConfig.aporteEnsayo;
  }

  Future<void> guardarMontoEnsayo(double monto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMonto, monto);
  }

  Future<int> leerDiasCriticos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kCriticos) ?? ApiConfig.diasCriticos;
  }

  Future<void> guardarDiasCriticos(int dias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCriticos, dias);
  }
}
