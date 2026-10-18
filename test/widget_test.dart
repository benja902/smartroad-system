import 'package:flutter_test/flutter_test.dart';

import 'package:smartroad/app.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('App boots into Home tab with bottom navigation', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(mockAppProviders(child: const UrbesApp()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'URBES')), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Alertas'), findsOneWidget);
      expect(find.text('Vehículo'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
