/// Configuracion central de la API.
///
/// IMPORTANTE: Reemplaza la URL por la que genera Google Apps Script
/// al desplegar el backend como "Web app" (ver archivo backend/appsscript.gs).
class ApiConfig {
  ApiConfig._();

  /// URL del Web App (Google Apps Script).
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbyV2gqsOom2T_XV2TNqS63m3TcaLqUa7iDjddqS3Cbw3b6__aEWmCKN0Ki5KW52MGPhRA/exec';

  /// Token secreto para autorizar las peticiones al backend.
  ///
  /// Debe coincidir con la constante `API_TOKEN` en backend/appsscript.gs.
  /// Evita que cualquiera con la URL publique integrantes o registre pagos.
  static const String tokenSecreto =
      'CAP03-T0K3N-S3CR3T0-2026'; // TODO: reemplazar

  /// Clave para firmar los QR de los carnets (anti-falsificacion).
  ///
  /// El QR guarda "<id>.<HMAC-SHA256(id)>" y el escaner lo verifica antes
  /// de registrar el pago. Manten esta clave privada y fija.
  static const String qrClaveSecreta =
      'CAPORALES-QR-S3CR3TA'; // TODO: reemplazar

  /// Valor del aporte por ensayo (S/ 1.00 por defecto, editable en la app).
  static const double aporteEnsayo = 1.00;

  /// Umbral de inasistencias criticas (en dias).
  static const int diasCriticos = 14;
}
