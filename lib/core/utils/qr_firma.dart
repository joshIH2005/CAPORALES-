import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/api_config.dart';

/// Firma HMAC de los QR para evitar carnets falsificados.
///
/// El carnet guarda en el QR: `"<id>.<hmac>"` donde `hmac` es
/// `HMAC-SHA256(id)` calculado con [ApiConfig.qrClaveSecreta]. El escaner
/// solo acepta QRs cuya firma sea valida, por lo que no basta con conocer
/// el ID de un integrante para fabricar un carnet.
class QrFirma {
  QrFirma._();

  static const String _separador = '.';

  /// Genera el contenido firmado del QR para el [id] del integrante.
  static String firmar(String id) {
    final hmac = _hmac(id);
    return '$id$_separador$hmac';
  }

  /// Valida el contenido escaneado y devuelve el ID del integrante.
  ///
  /// Devuelve `null` si el QR no esta firmado o la firma no coincide
  /// (carnet falsificado, desactualizado o dañado).
  static String? validar(String contenidoQr) {
    final contenido = contenidoQr.trim();
    if (contenido.isEmpty) return null;

    final idx = contenido.lastIndexOf(_separador);
    if (idx <= 0 || idx == contenido.length - 1) return null;

    final id = contenido.substring(0, idx);
    final firma = contenido.substring(idx + 1);

    if (firma != _hmac(id)) return null;
    return id;
  }

  /// HMAC-SHA256 en hexadecimal (64 caracteres) del [id].
  static String _hmac(String id) {
    final hmac = Hmac(sha256, utf8.encode(ApiConfig.qrClaveSecreta));
    return hmac.convert(utf8.encode(id)).toString();
  }
}
