import 'package:caporales_app/core/utils/qr_firma.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'CAP-260920-1234';

  test('firmar genera "<id>.<firma>"', () {
    final contenido = QrFirma.firmar(id);
    expect(contenido.startsWith('$id.'), isTrue);
    expect(contenido.length, id.length + 1 + 64); // HMAC-SHA256 hex = 64
  });

  test('validar acepta el QR firmado correctamente', () {
    expect(QrFirma.validar(QrFirma.firmar(id)), id);
  });

  test('validar rechaza un QR sin firmar (solo el ID)', () {
    expect(QrFirma.validar(id), isNull);
  });

  test('validar rechaza una firma alterada', () {
    final contenido = QrFirma.firmar(id);
    expect(QrFirma.validar('${contenido}x'), isNull);
  });

  test('validar rechaza la firma de otro integrante', () {
    final contenido = QrFirma.firmar(id);
    final firma = contenido.split('.').last;
    expect(QrFirma.validar('CAP-260920-9999.$firma'), isNull);
  });

  test('validar rechaza contenido vacio', () {
    expect(QrFirma.validar(''), isNull);
    expect(QrFirma.validar('   '), isNull);
  });

  test('la firma es determinista (mismo id -> misma firma)', () {
    expect(QrFirma.firmar(id), QrFirma.firmar(id));
  });
}
