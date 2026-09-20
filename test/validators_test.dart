import 'package:caporales_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.textoRequerido', () {
    test('rechaza valores vacios', () {
      expect(Validators.textoRequerido(null), isNotNull);
      expect(Validators.textoRequerido(''), isNotNull);
      expect(Validators.textoRequerido('   '), isNotNull);
    });

    test('acepta texto con contenido', () {
      expect(Validators.textoRequerido('Ana'), isNull);
    });
  });

  group('Validators.soloLetras', () {
    test('acepta letras y espacios (con acentos y ñ)', () {
      expect(Validators.soloLetras('Ana María Pérez'), isNull);
      expect(Validators.soloLetras('JOSÉ ÑAÑEZ'), isNull);
    });

    test('rechaza digitos y simbolos', () {
      expect(Validators.soloLetras('Ana 123'), isNotNull);
      expect(Validators.soloLetras('Ana@'), isNotNull);
    });
  });

  group('Validators.numeroPositivo', () {
    test('acepta edades validas', () {
      expect(Validators.numeroPositivo('0'), isNull);
      expect(Validators.numeroPositivo('25'), isNull);
      expect(Validators.numeroPositivo('120'), isNull);
    });

    test('rechaza edades invalidas', () {
      expect(Validators.numeroPositivo(null), isNotNull);
      expect(Validators.numeroPositivo(''), isNotNull);
      expect(Validators.numeroPositivo('-1'), isNotNull);
      expect(Validators.numeroPositivo('121'), isNotNull);
      expect(Validators.numeroPositivo('abc'), isNotNull);
    });
  });

  group('Validators.fechaNoFutura', () {
    test('rechaza fecha futura', () {
      final manana = DateTime.now().add(const Duration(days: 1));
      expect(Validators.fechaNoFutura(manana), isNotNull);
    });

    test('acepta fecha pasada', () {
      expect(Validators.fechaNoFutura(DateTime(1990, 1, 1)), isNull);
    });

    test('rechaza valor nulo', () {
      expect(Validators.fechaNoFutura(null), isNotNull);
    });
  });

  group('Validators.telefonoOpcional', () {
    test('acepta vacio (opcional)', () {
      expect(Validators.telefonoOpcional(null), isNull);
      expect(Validators.telefonoOpcional(''), isNull);
      expect(Validators.telefonoOpcional('   '), isNull);
    });

    test('acepta telefonos validos (7-15 digitos)', () {
      expect(Validators.telefonoOpcional('987654321'), isNull);
      expect(Validators.telefonoOpcional('+51 987 654 321'), isNull);
      expect(Validators.telefonoOpcional('(01) 234-5678'), isNull);
    });

    test('rechaza telefonos cortos', () {
      expect(Validators.telefonoOpcional('123'), isNotNull);
      expect(Validators.telefonoOpcional('abcde123'), isNotNull);
    });
  });
}
