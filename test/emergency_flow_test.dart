import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smartroad/app.dart';
import 'package:smartroad/models/accident_severity.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/mock/mock_event_repository.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('Grave crash forces the active-emergency screen with real actions only', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerCrash();
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsOneWidget);
    expect(find.text('LLAMAR A EMERGENCIAS'), findsOneWidget);
    // No confirm/cancel affordances — the app can't originate either.
    expect(find.text('Necesito ayuda ahora'), findsNothing);
    expect(find.text('Cancelar alerta'), findsNothing);
  });

  testWidgets('SOS forces the same active-emergency screen', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerSos();
    await tester.pumpAndSettle();

    expect(find.text('AUXILIO SOLICITADO'), findsOneWidget);
  });

  testWidgets('Queued grave crash never forces the critical screen', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerCrash(queued: true);
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('A cancel referencing the active event closes the critical screen', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    final event = repo.triggerCrash();
    await tester.pumpAndSettle();
    expect(find.text('CHOQUE SEVERO DETECTADO'), findsOneWidget);

    repo.triggerCancel(event.seq);
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('"Ya lo vi" acknowledges the event and closes the critical screen', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerCrash();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ya lo vi — marcar como atendido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya lo vi — marcar como atendido'));
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('Moderado crash does not force the critical screen', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(mockAppProviders(child: UrbesApp(key: key)));
    await tester.pumpAndSettle();

    final context = key.currentContext!;
    final repo = context.read<EventRepository>() as MockEventRepository;

    repo.triggerCrash(severity: AccidentSeverity.moderado);
    await tester.pumpAndSettle();

    expect(find.text('CHOQUE SEVERO DETECTADO'), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
  });
}
