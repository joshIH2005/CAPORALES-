import '../../core/utils/formatters.dart';

/// Modelo de datos de un registro de pago/asistencia.
class Record {
  final String id;
  final String memberId;
  final String memberName;
  final String fecha; // Formato: yyyy-MM-dd
  final String hora; // Formato: HH:mm:ss
  final double monto;
  final bool asistencia;

  const Record({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.fecha,
    required this.hora,
    required this.monto,
    required this.asistencia,
  });

  /// Convierte el objeto a un Map para enviarlo por HTTP / JSON.
  Map<String, dynamic> toMap() => {
        'id': id,
        'member_id': memberId,
        'member_name': memberName,
        'fecha': fecha,
        'hora': hora,
        'monto': monto,
        'asistencia': asistencia,
      };

  /// Construye un [Record] a partir de un Map (respuesta del API).
  factory Record.fromMap(Map<String, dynamic> map) => Record(
        id: map['id']?.toString() ?? '',
        memberId: map['member_id']?.toString() ?? '',
        memberName: map['member_name']?.toString() ?? '',
        fecha:
            Formatters.fechaISODesde(map['fecha']?.toString() ?? '2020-01-01'),
        hora: map['hora']?.toString() ?? '',
        monto: double.tryParse(map['monto']?.toString() ?? '0') ?? 0.0,
        asistencia:
            (map['asistencia']?.toString() ?? '').toLowerCase() == 'true',
      );
}
