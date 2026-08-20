import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smartroad/app.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('Level3 detection forces immediate navigation with no countdown', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerLevel3();
    await tester.pumpAndSettle();

    expect(find.text('ACCIDENTE SEVERO DETECTADO'), findsOneWidget);
    expect(find.text('LLAMAR A EMERGENCIAS'), findsOneWidget);
    // No countdown/cancel affordances on Nivel 3.
    expect(find.text('Cancelar alerta'), findsNothing);
  });

  testWidgets('Level2 detection shows countdown; cancel returns to Home', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerLevel2();
    await tester.pumpAndSettle();

    expect(find.text('POSIBLE ACCIDENTE DETECTADO'), findsOneWidget);
    expect(find.text('Cancelar alerta'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancelar alerta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar alerta'));
    await tester.pumpAndSettle();

    expect(find.text('POSIBLE ACCIDENTE DETECTADO'), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('Level2 confirmEmergency transitions to active state on the same route', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerLevel2();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Necesito ayuda ahora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Necesito ayuda ahora'));
    await tester.pumpAndSettle();

    expect(find.text('EMERGENCIA EN CURSO'), findsOneWidget);
  });
}
