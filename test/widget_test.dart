import 'package:flutter_test/flutter_test.dart';

import 'package:caporales_app/logic/member_controller.dart';
import 'package:caporales_app/main.dart';

void main() {
  testWidgets('Splash screen shows identity and navigates to main menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CaporalesApp(controller: MemberController()),
    );
    await tester.pump();

    // Splash: identidad del elenco.
    expect(find.text('NOBLEZA'), findsOneWidget);
    expect(find.text('CAPO RAL'), findsOneWidget);

    // Transicion automatica al menu principal (timer 4200ms).
    await tester.pump(const Duration(milliseconds: 4300));
    await tester.pump(const Duration(milliseconds: 400));

    // Los accesos rapidos quedan bajo el pliegue en el viewport de prueba.
    await tester.scrollUntilVisible(find.text('Nuevo integrante'), 120);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Escaner QR'), findsOneWidget);
    expect(find.text('Nuevo integrante'), findsOneWidget);
  });
}
