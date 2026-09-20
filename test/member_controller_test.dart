import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:caporales_app/core/constants/api_config.dart';
import 'package:caporales_app/core/utils/formatters.dart';
import 'package:caporales_app/data/providers/api_service.dart';
import 'package:caporales_app/logic/member_controller.dart';

/// Respuesta GET "stats" de ejemplo.
http.Response statsResponse(
  List<Map<String, dynamic>> integrantes,
  List<Map<String, dynamic>> registros,
) =>
    http.Response(
      jsonEncode({
        'ok': true,
        'integrantes': integrantes,
        'registros': registros,
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response okResponse() => http.Response(
      jsonEncode({'ok': true, 'mensaje': 'ok'}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> miembroMap({
  String id = 'CAP-260920-0001',
  String nombre = 'Ana Pérez',
}) =>
    {
      'id': id,
      'nombres_apellidos': nombre,
      'edad': 25,
      'fecha_nacimiento': '2000-05-10',
      'ocupacion': 'Estudiante',
      'estado': 'Activo',
      'fecha_ingreso': '2026-01-10',
      'telefono': '987654321',
    };

Map<String, dynamic> registroMap({
  required String memberId,
  String fecha = '',
  String id = 'r1',
}) =>
    {
      'id': id,
      'member_id': memberId,
      'member_name': 'Ana Pérez',
      'fecha': fecha.isEmpty ? Formatters.hoyISO() : fecha,
      'hora': '19:30:00',
      'monto': 1.0,
      'asistencia': true,
    };

String _iso(DateTime fecha) {
  final dd = fecha.day.toString().padLeft(2, '0');
  final mm = fecha.month.toString().padLeft(2, '0');
  return '${fecha.year}-$mm-$dd';
}

MemberController _crearController(MockClient client) => MemberController(
      api: ApiService(client: client),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MiembroController: cobros por QR', () {
    test('detecta pago duplicado del mismo dia', () async {
      final client = MockClient((req) async {
        if (req.method == 'GET') {
          return statsResponse(
            [miembroMap()],
            [registroMap(memberId: 'CAP-260920-0001')],
          );
        }
        return okResponse();
      });

      final controller = _crearController(client);
      await controller.cargarDatos();

      final res = await controller.registrarPagoPorId('CAP-260920-0001');
      expect(res.esDuplicado, isTrue);
      expect(res.exitoso, isFalse);
      // No se registra un segundo pago.
      expect(controller.records.length, 1);
    });

    test('registra el pago nuevo y lo envia por POST firmado', () async {
      final posts = <String>[];
      final client = MockClient((req) async {
        if (req.method == 'GET') {
          return statsResponse([miembroMap()], []);
        }
        posts.add(req.body);
        return okResponse();
      });

      final controller = _crearController(client);
      await controller.cargarDatos();

      final res = await controller.registrarPagoPorId('CAP-260920-0001');
      expect(res.exitoso, isTrue);
      expect(res.pendiente, isFalse);
      expect(controller.records.length, 1);

      final cuerpo = jsonDecode(posts.single) as Map<String, dynamic>;
      expect(cuerpo['accion'], 'registrar_pago');
      expect(cuerpo['token'], ApiConfig.tokenSecreto);
      expect(cuerpo['datos']['member_id'], 'CAP-260920-0001');
      expect(cuerpo['datos']['monto'], ApiConfig.aporteEnsayo);
    });

    test('sin conexion el pago queda pendiente de sincronizar', () async {
      var online = true;
      final client = MockClient((req) async {
        if (!online) throw http.ClientException('sin conexion');
        if (req.method == 'GET') {
          return statsResponse([miembroMap()], []);
        }
        return okResponse();
      });

      final controller = _crearController(client);
      await controller.cargarDatos();
      expect(controller.offline, isFalse);

      online = false;
      final res = await controller.registrarPagoPorId('CAP-260920-0001');
      expect(res.exitoso, isTrue);
      expect(res.pendiente, isTrue);
      expect(controller.records.length, 1);
      expect(controller.pendientes, 1);

      // Al recuperar la conexion se sincroniza.
      online = true;
      await controller.sincronizarTodo();
      expect(controller.pendientes, 0);
    });
  });

  group('MiembroController: offline / cache', () {
    test('cargarDatos sin conexion usa el ultimo snapshot local', () async {
      final client = MockClient((req) async {
        if (req.method == 'GET') {
          return statsResponse([miembroMap()], []);
        }
        return okResponse();
      });

      final controller = _crearController(client);
      await controller.cargarDatos();
      expect(controller.members.length, 1);

      // Nuevo arranque sin conexion.
      final offlineClient = MockClient((req) async {
        throw http.ClientException('sin conexion');
      });
      final offline = _crearController(offlineClient);
      await offline.cargarDatos();

      expect(offline.members.length, 1);
      expect(offline.records, isEmpty);
      expect(offline.offline, isTrue);
      expect(offline.error, isNull); // Hay cache: sin error fatal.
    });
  });

  group('MiembroController: criticos', () {
    test('marca quien supero el umbral de dias sin asistencia', () async {
      final ahora = DateTime.now();
      final hace20 = ahora.subtract(const Duration(days: 20));
      final hace3 = ahora.subtract(const Duration(days: 3));

      final client = MockClient((req) async {
        if (req.method == 'GET') {
          return statsResponse(
            [
              miembroMap(id: 'ID-A', nombre: 'Ana'),
              miembroMap(id: 'ID-B', nombre: 'Beto'),
              miembroMap(id: 'ID-C', nombre: 'Carla'),
            ],
            [
              registroMap(memberId: 'ID-A', fecha: _iso(hace20), id: 'r1'),
              registroMap(memberId: 'ID-B', fecha: _iso(hace3), id: 'r2'),
            ],
          );
        }
        return okResponse();
      });

      final controller = _crearController(client);
      await controller.cargarDatos();

      final criticos =
          controller.inasistenciasCriticas.map((m) => m.id).toSet();
      expect(criticos, contains('ID-A')); // +20 dias: critico
      expect(criticos, isNot(contains('ID-B'))); // hace 3 dias: al dia
      expect(criticos, contains('ID-C')); // nunca asistio: critico

      expect(controller.diasSinAsistencia('ID-A'), greaterThanOrEqualTo(20));
      expect(controller.diasSinAsistencia('ID-C'), isNull);
    });

    test('diasSinAsistencia respeta fechas puras sin desfase UTC', () {
      // Una fecha UTC de Apps Script (05:00Z) no puede correr el dia.
      const utc = '2026-09-20T05:00:00.000Z';
      expect(Formatters.fechaISODesde(utc), '2026-09-20');
    });
  });

  group('MiembroController: alta y anulacion', () {
    test('crearMiembro envia telefono y token', () async {
      final posts = <String>[];
      final client = MockClient((req) async {
        if (req.method == 'GET') return statsResponse([], []);
        posts.add(req.body);
        return okResponse();
      });

      final controller = _crearController(client);
      final (ok, _, creado) = await controller.crearMiembro(
        nombresApellidos: 'Luis Díaz',
        edad: 30,
        fechaNacimiento: '1996-01-01',
        ocupacion: 'Bailarín',
        telefono: '987654321',
      );

      expect(ok, isTrue);
      expect(creado, isNotNull);

      final cuerpo = jsonDecode(posts.single) as Map<String, dynamic>;
      expect(cuerpo['accion'], 'nuevo_miembro');
      expect(cuerpo['token'], ApiConfig.tokenSecreto);
      expect(cuerpo['datos']['telefono'], '987654321');
      expect(controller.members.length, 1);
    });

    test('anularPago quita el registro y envia la anulacion', () async {
      final posts = <String>[];
      final client = MockClient((req) async {
        if (req.method == 'GET') {
          return statsResponse(
            [miembroMap()],
            [registroMap(memberId: 'CAP-260920-0001', id: 'r1')],
          );
        }
        posts.add(req.body);
        return okResponse();
      });

      final controller = _crearController(client);
      await controller.cargarDatos();
      expect(controller.records.length, 1);

      final res = await controller.anularPago(controller.records.first);
      expect(res.ok, isTrue);
      expect(controller.records, isEmpty);

      final cuerpo = jsonDecode(posts.single) as Map<String, dynamic>;
      expect(cuerpo['accion'], 'eliminar_registro');
      expect(cuerpo['datos']['id'], 'r1');
    });
  });

  group('MiembroController: recaudado del mes', () {
    test('suma solo los montos del mes en curso', () async {
      final ahora = DateTime.now();
      final mes = ahora.month.toString().padLeft(2, '0');

      final client = MockClient((req) async {
        if (req.method == 'GET') {
          return statsResponse(
            [miembroMap(id: 'ID-A')],
            [
              registroMap(
                  memberId: 'ID-A', fecha: '${ahora.year}-$mes-01', id: 'r1'),
              registroMap(
                  memberId: 'ID-A', fecha: '${ahora.year}-$mes-15', id: 'r2'),
            ],
          );
        }
        return okResponse();
      });

      final controller = _crearController(client);
      await controller.cargarDatos();

      expect(controller.recaudadoDelMes, 2.0);
      expect(controller.totalRecaudado, 2.0);
    });
  });
}
