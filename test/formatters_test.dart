import 'package:caporales_app/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.soles', () {
    test('formatea siempre con 2 decimales', () {
      expect(Formatters.soles(1), 'S/ 1.00');
      expect(Formatters.soles(12.5), 'S/ 12.50');
      expect(Formatters.soles(1.0), 'S/ 1.00');
      expect(Formatters.soles(0), 'S/ 0.00');
      expect(Formatters.soles(99.999), 'S/ 100.00');
    });
  });

  group('Formatters.fechaISODesde', () {
    test('quita la parte de hora (UTC de Apps Script)', () {
      expect(
        Formatters.fechaISODesde('2026-09-20T05:00:00.000Z'),
        '2026-09-20',
      );
      expect(Formatters.fechaISODesde('2026-09-20 19:30:00'), '2026-09-20');
      expect(Formatters.fechaISODesde('2026-09-20'), '2026-09-20');
    });
  });

  group('Formatters.parsearFecha', () {
    test('devuelve null para valores vacios o invalidos', () {
      expect(Formatters.parsearFecha(null), isNull);
      expect(Formatters.parsearFecha(''), isNull);
      expect(Formatters.parsearFecha('  '), isNull);
    });

    test('parsea fechas "yyyy-MM-dd" como local', () {
      final fecha = Formatters.parsearFecha('2026-09-20');
      expect(fecha, isNotNull);
      expect(fecha!.year, 2026);
      expect(fecha.month, 9);
      expect(fecha.day, 20);
    });
  });

  group('Formatters fechas y numeros', () {
    test('fechaCorta usa dd/mm/yyyy', () {
      expect(Formatters.fechaCorta(DateTime(2026, 9, 5)), '05/09/2026');
    });

    test('horaCorta usa HH:mm:ss', () {
      expect(Formatters.horaCorta(DateTime(2026, 9, 5, 19, 30, 5)), '19:30:05');
    });

    test('hoyISO respeta el formato yyyy-MM-dd', () {
      final hoy = Formatters.hoyISO();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(hoy), isTrue);
      expect(hoy, Formatters.fechaISODesde(hoy));
    });

    test('claveMes y etiquetaMes', () {
      expect(Formatters.claveMes(DateTime(2026, 9, 20)), '2026-09');
      expect(Formatters.etiquetaMes('2026-09'), 'Septiembre 2026');
      expect(Formatters.etiquetaMes('mal'), 'mal');
    });

    test('generarIdMiembro tiene el patron CAP-YYMMDD-RRRR', () {
      final id = Formatters.generarIdMiembro();
      expect(RegExp(r'^CAP-\d{6}-\d{4}$').hasMatch(id), isTrue);
    });
  });
}
