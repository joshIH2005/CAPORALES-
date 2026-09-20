/// Configuracion central de la API.
///
/// Los valores secretos (token y clave QR) NO van en este archivo.
/// Se inyectan en compilacion con --dart-define para no filtrarlos en un
/// repositorio publico. Ejemplos:
///   flutter run --dart-define=API_TOKEN='...' --dart-define=QR_CLAVE='...'
///   flutter build apk --dart-define=API_TOKEN='...' --dart-define=QR_CLAVE='...'
///
/// Deben coincidir con API_TOKEN y QR_CLAVE de backend/appsscript.gs.
class ApiConfig {
  ApiConfig._();

  /// URL del Web App (Google Apps Script).
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbyV2gqsOom2T_XV2TNqS63m3TcaLqUa7iDjddqS3Cbw3b6__aEWmCKN0Ki5KW52MGPhRA/exec';

  /// Token secreto para autorizar las peticiones al backend.
  ///
  /// Inyectalo con --dart-define=API_TOKEN='...' al compilar/ejecutar.
  static const String tokenSecreto = String.fromEnvironment('API_TOKEN');

  /// Clave para firmar los QR de los carnets (anti-falsificacion).
  ///
  /// El QR guarda "<id>.<HMAC-SHA256(id)>" y el escaner lo verifica antes
  /// de registrar el pago. Inyectala con --dart-define=QR_CLAVE='...'.
  static const String qrClaveSecreta = String.fromEnvironment('QR_CLAVE');

  /// Valor del aporte por ensayo (S/ 1.00 por defecto, editable en la app).
  static const double aporteEnsayo = 1.00;

  /// Umbral de inasistencias criticas (en dias).
  static const int diasCriticos = 14;
}
