import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import '../models/member_model.dart';
import '../models/record_model.dart';

/// Resultado de una escritura en el backend.
class ResultadoEscritura {
  final bool ok;
  final String? error;

  const ResultadoEscritura({required this.ok, this.error});
}

/// Cliente HTTP que se comunica con la API de Google Apps Script.
///
/// Las lecturas usan GET; las escrituras se envian por POST con el redirect
/// (302) que devuelve Apps Script manejado a mano. En la Web (navegador) el
/// fetch convierte ese 302 en GET (405), por lo que las escrituras pequeñas
/// caen de nuevo al GET como retrocompatibilidad.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Longitud maxima (bytes) que aceptamos en la URL para el GET fallback.
  static const int _limiteUrlGet = 3500;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  /// Envia un nuevo integrante a la hoja "Integrantes".
  Future<ResultadoEscritura> crearMiembro(Member member) async {
    final json = await _escribir(
      accion: 'nuevo_miembro',
      datos: member.toMap(),
    );
    return _resultado(json);
  }

  /// Actualiza los datos de un integrante existente (mismo ID).
  Future<ResultadoEscritura> actualizarMiembro(Member member) async {
    final json = await _escribir(
      accion: 'actualizar_miembro',
      datos: member.toMap(),
    );
    return _resultado(json);
  }

  /// Envia un registro de pago/asistencia a la hoja "Registros".
  Future<ResultadoEscritura> registrarPago(Record record) async {
    final json = await _escribir(
      accion: 'registrar_pago',
      datos: record.toMap(),
    );
    return _resultado(json);
  }

  /// Anula (elimina) un registro de pago por su ID.
  Future<ResultadoEscritura> anularRegistro(String recordId) async {
    final json = await _escribir(
      accion: 'eliminar_registro',
      datos: {'id': recordId},
    );
    return _resultado(json);
  }

  /// Descarga todos los integrantes y registros desde la API.
  ///
  /// Devuelve un mapa con las listas [members] y [records].
  Future<({List<Member> members, List<Record> records})> obtenerDatos() async {
    final uri = Uri.parse(ApiConfig.baseUrl).replace(
      queryParameters: {
        'accion': 'stats',
        'token': ApiConfig.tokenSecreto,
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));

    final json = _decodificar(response);
    if (json is Map<String, dynamic> && json['ok'] != true) {
      throw Exception(json['error']?.toString() ?? 'API no autorizada');
    }

    final membersJson = (json['integrantes'] as List<dynamic>? ?? []);
    final recordsJson = (json['registros'] as List<dynamic>? ?? []);

    final members = membersJson
        .map((e) => Member.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final records = recordsJson
        .map((e) => Record.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return (members: members, records: records);
  }

  // ===== Metodos privados de apoyo =====

  /// Envia una escritura al backend.
  ///
  /// Prefiere POST (con manejo manual del redirect 302 de Apps Script).
  /// Si el POST no responde de forma definitiva y el payload cabe en una
  /// URL, reintenta por GET (funciona en la web y con implementaciones
  /// antiguas del backend).
  Future<dynamic> _escribir({
    required String accion,
    required Map<String, dynamic> datos,
  }) async {
    final datosJson = jsonEncode(datos);

    // En la web el navegador convierte el 302 en GET, imposible reenviar
    // el cuerpo del POST; se usa GET directamente si el payload cabe.
    if (kIsWeb) {
      if (datosJson.length > _limiteUrlGet) {
        throw Exception(
          'Los datos son demasiado grandes para la version web. '
          'Usala desde la app Android.',
        );
      }
      return _escribirPorGet(accion: accion, datosJson: datosJson);
    }

    try {
      final respuesta = await _enviarPost(accion: accion, datos: datos);
      return _decodificar(respuesta);
    } catch (e) {
      debugPrint('_escribir (POST -> fallback GET): $e');
      if (datosJson.length > _limiteUrlGet) {
        throw Exception('No se pudo escribir: $e');
      }
      return _escribirPorGet(accion: accion, datosJson: datosJson);
    }
  }

  /// POST con manejo manual del redirect 302 de Apps Script.
  Future<http.Response> _enviarPost({
    required String accion,
    required Map<String, dynamic> datos,
  }) async {
    final cuerpo = jsonEncode({
      'accion': accion,
      'datos': datos,
      'token': ApiConfig.tokenSecreto,
    });

    var uri = Uri.parse(ApiConfig.baseUrl);
    var response = await _client
        .post(uri, headers: _jsonHeaders, body: cuerpo)
        .timeout(const Duration(seconds: 20));

    // Apps Script redirige (302); reenviamos el POST a la URL indicada.
    if (_esRedirect(response.statusCode)) {
      final location = response.headers['location'];
      if (location == null || location.isEmpty) {
        throw Exception('Redirect sin Location');
      }
      uri = Uri.parse(location);
      response = await _client
          .post(uri, headers: _jsonHeaders, body: cuerpo)
          .timeout(const Duration(seconds: 20));
    }
    return response;
  }

  /// GET con los datos en la URL (retrocompatibilidad y web).
  Future<dynamic> _escribirPorGet({
    required String accion,
    required String datosJson,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl).replace(
      queryParameters: {
        'accion': accion,
        'datos': datosJson,
        'token': ApiConfig.tokenSecreto,
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    return _decodificar(response);
  }

  static bool _esRedirect(int statusCode) =>
      statusCode >= 300 && statusCode < 400;

  /// Decodifica la respuesta HTTP en JSON si fue 200, si no lanza.
  dynamic _decodificar(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} al consultar la API');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Convierte la respuesta del backend en [ResultadoEscritura].
  ResultadoEscritura _resultado(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ResultadoEscritura(
        ok: json['ok'] == true,
        error: json['error']?.toString(),
      );
    }
    return const ResultadoEscritura(
      ok: false,
      error: 'Respuesta inválida del servidor',
    );
  }
}