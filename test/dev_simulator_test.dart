import 'package:flutter_test/flutter_test.dart';

import 'package:smartroad/app.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Production app (includeDevRoute: false) hides the /dev entry point', (tester) async {
    await tester.pumpWidget(mockAppProviders(child: const UrbesApp()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Panel de desarrollo'), findsNothing);
  });

  testWidgets('Dev app exposes the /dev panel and its toggles affect Home live', (tester) async {
    await tester.pumpWidget(mockAppProviders(child: const UrbesApp(includeDevRoute: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Panel de desarrollo'));
    await tester.pumpAndSettle();

    expect(find.text('Panel de desarrollo'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Simular Nivel 3'), 300);
    expect(find.text('Simular Nivel 3'), findsOneWidget);

    await tester.tap(find.text('Simular Nivel 3'));
    await tester.pumpAndSettle();

    // Triggering Level3 from /dev must force navigation to the critical
    // route immediately, same as if the hardware had reported it.
    expect(find.text('ACCIDENTE SEVERO DETECTADO'), findsOneWidget);
  });
}
