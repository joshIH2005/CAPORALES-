import '../../core/utils/formatters.dart';

/// Modelo de datos de un integrante del elenco.
class Member {
  final String id;
  final String nombresApellidos;
  final int edad;
  final String fechaNacimiento; // Formato: yyyy-MM-dd
  final String ocupacion;
  final String estado; // Activo / Inactivo
  final String fechaIngreso; // Formato: yyyy-MM-dd
  final String telefono; // Opcional

  const Member({
    required this.id,
    required this.nombresApellidos,
    required this.edad,
    required this.fechaNacimiento,
    required this.ocupacion,
    required this.estado,
    required this.fechaIngreso,
    this.telefono = '',
  });

  /// Convierte el objeto a un Map para enviarlo por HTTP / JSON.
  Map<String, dynamic> toMap() => {
        'id': id,
        'nombres_apellidos': nombresApellidos,
        'edad': edad,
        'fecha_nacimiento': fechaNacimiento,
        'ocupacion': ocupacion,
        'estado': estado,
        'fecha_ingreso': fechaIngreso,
        'telefono': telefono,
      };

  /// Construye un [Member] a partir de un Map (respuesta del API).
  factory Member.fromMap(Map<String, dynamic> map) => Member(
        id: map['id']?.toString() ?? '',
        nombresApellidos: map['nombres_apellidos']?.toString() ?? '',
        edad: int.tryParse(map['edad']?.toString() ?? '0') ?? 0,
        fechaNacimiento:
            Formatters.fechaISODesde(map['fecha_nacimiento']?.toString() ?? ''),
        ocupacion: map['ocupacion']?.toString() ?? '',
        estado: map['estado']?.toString() ?? 'Activo',
        fechaIngreso:
            Formatters.fechaISODesde(map['fecha_ingreso']?.toString() ?? ''),
        telefono: map['telefono']?.toString() ?? '',
      );

  /// Nombre en mayusculas (para el carnet digital).
  String get nombreUpper => nombresApellidos.toUpperCase();
}
