/// Utilidades de formato (fechas, monedas, ids).
class Formatters {
  Formatters._();

  /// Convierte un numero a soles peruanos: 25.5 -> "S/ 25.50"
  static String soles(num value) {
    final string = value.toStringAsFixed(2);
    return 'S/ $string';
  }

  /// Formatea una fecha como "15/09/2026".
  static String fechaCorta(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final yyyy = fecha.year.toString();
    return '$dd/$mm/$yyyy';
  }

  /// Formatea la hora como "19:30:00".
  static String horaCorta(DateTime hora) {
    final hh = hora.hour.toString().padLeft(2, '0');
    final mm = hora.minute.toString().padLeft(2, '0');
    final ss = hora.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  /// Obtiene la fecha de hoy en formato ISO (yyyy-MM-dd).
  static String hoyISO() {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  /// Genera un ID unico para integrantes: CAP-YYMMDD-RRRR
  static String generarIdMiembro() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final rnd =
        (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return 'CAP-$yy$mm$dd-$rnd';
  }

  /// Normaliza cualquier fecha (ISO-UTC, con hora, etc.) a "yyyy-MM-dd".
  ///
  /// Google Sheets guarda las fechas como Date y al leerlas Apps Script las
  /// devuelve como "2026-09-20T05:00:00.000Z". Con esto la app siempre
  /// trabaja con la parte de fecha pura para evitar desfases de un dia.
  static String fechaISODesde(String value) {
    var limpia = value.trim();
    final idxT = limpia.indexOf('T');
    if (idxT != -1) limpia = limpia.substring(0, idxT);
    final idxEspacio = limpia.indexOf(' ');
    if (idxEspacio != -1) limpia = limpia.substring(0, idxEspacio);
    return limpia;
  }

  /// Parsea una fecha "yyyy-MM-dd" como DateTime local (medianoche).
  static DateTime? parsearFecha(String? fechaISO) {
    if (fechaISO == null || fechaISO.isEmpty) return null;
    return DateTime.tryParse(fechaISODesde(fechaISO));
  }

  /// Nombre completo de un mes (1-12), en espanol.
  static String nombreMes(int mes) {
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
    if (mes < 1 || mes > 12) return '';
    return meses[mes - 1];
  }

  /// Clave "yyyy-MM" para agrupar registros por mes.
  static String claveMes(DateTime fecha) {
    final mm = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mm';
  }

  /// Etiqueta legible de una clave de mes "yyyy-MM" -> "Septiembre 2026".
  static String etiquetaMes(String claveMes) {
    final partes = claveMes.split('-');
    if (partes.length != 2) return claveMes;
    final anio = int.tryParse(partes[0]) ?? 0;
    final mes = int.tryParse(partes[1]) ?? 0;
    final nombre = nombreMes(mes);
    if (nombre.isEmpty) return claveMes;
    var texto = '$nombre $anio';
    return texto[0].toUpperCase() + texto.substring(1);
  }
}
