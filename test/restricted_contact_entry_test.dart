import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smartroad/app.dart';
import 'package:smartroad/models/accident_event.dart';
import 'package:smartroad/models/device_status.dart';
import 'package:smartroad/models/user_model.dart';
import 'package:smartroad/models/vehicle_model.dart';
import 'package:smartroad/repositories/auth_repository.dart';
import 'package:smartroad/repositories/firebase/firebase_contact_operations.dart';
import 'package:smartroad/repositories/device_repository.dart';
import 'package:smartroad/repositories/event_repository.dart';
import 'package:smartroad/repositories/firebase/firebase_contact_relation_repository.dart';
import 'package:smartroad/repositories/vehicle_repository.dart';
import 'package:smartroad/screens/auth/login_screen.dart';
import 'package:smartroad/screens/contacts/pending_invitation_screen.dart';
import 'package:smartroad/screens/home/home_screen.dart';
import 'package:smartroad/state/app_providers.dart';
import 'package:smartroad/state/device_status_provider.dart';
import 'package:smartroad/state/event_provider.dart';
import 'package:smartroad/state/vehicle_provider.dart';

const owner = UserModel(
  id: 'owner-test',
  name: 'Owner',
  email: 'owner@example.test',
);
const contact = UserModel(
  id: 'contact-test',
  name: 'Contact',
  email: 'contact@example.test',
);
const vehicle = VehicleModel(
  id: 'vehicle-test',
  ownerId: 'owner-test',
  deviceId: 'SDA-TEST',
  brand: 'Test',
  model: 'Model',
  plate: 'PRIVATE-OWNER',
);

class _Auth extends Fake implements AuthRepository {
  Completer<UserModel>? pendingSignIn;
  Object? signOutError;
  UserModel? current;
  final changes = StreamController<UserModel?>.broadcast(sync: true);
  _Auth(this.current);
  @override
  Stream<UserModel?> authStateChanges() async* {
    yield current;
    yield* changes.stream;
  }

  void change(UserModel? value) {
    current = value;
    changes.add(value);
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
    change(null);
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    if (pendingSignIn != null) return pendingSignIn!.future;
    change(contact);
    return contact;
  }
}

class _Vehicles extends Fake implements VehicleRepository {
  final streams = <String, StreamController<VehicleModel?>>{};
  final reads = <String>[];
  @override
  Stream<VehicleModel?> watchPrimaryVehicle(String uid) {
    reads.add(uid);
    return streams
        .putIfAbsent(
          uid,
          () => StreamController<VehicleModel?>.broadcast(sync: true),
        )
        .stream;
  }
}

class _Events extends Fake implements EventRepository {
  final reads = <String>[];
  @override
  Stream<List<AccidentEvent>> watchEvents(String uid, {String? vehicleId}) {
    reads.add('$uid/$vehicleId');
    return Stream.value([]);
  }
}

class _Devices extends Fake implements DeviceRepository {
  final reads = <String>[];
  @override
  Stream<DeviceStatus> watchStatus(String deviceId) {
    reads.add(deviceId);
    return Stream.value(
      DeviceStatus(
        deviceId: deviceId,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }
}

class _Harness {
  final _Auth auth;
  final vehicles = _Vehicles();
  final events = _Events();
  final devices = _Devices();
  final invitations = <String, StreamController<PendingInvitationResolution>>{};
  final references = <String>[];
  FirebaseContactOperations? operations;
  ContactRelationReader? statusReader;
  VehicleContactsReader? ownerContactsReader;
  _Harness(UserModel? user) : auth = _Auth(user);

  Future<void> mount(WidgetTester tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await auth.changes.close();
      for (final stream in vehicles.streams.values) {
        await stream.close();
      }
      for (final stream in invitations.values) {
        await stream.close();
      }
    });
    await tester.pumpWidget(
      AppProviders(
        authRepository: auth,
        contactOperations: operations,
        contactRelationReader: statusReader,
        vehicleContactsReader: ownerContactsReader,
        vehicleRepository: vehicles,
        eventRepository: events,
        deviceRepository: devices,
        pendingInvitationReader: (ref) {
          references.add(ref);
          return invitations
              .putIfAbsent(
                ref,
                () => StreamController<PendingInvitationResolution>.broadcast(
                  sync: true,
                ),
              )
              .stream;
        },
        child: const UrbesApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> restricted(WidgetTester tester) async {
    vehicles.streams[auth.current!.id]!.add(null);
    await tester.pumpAndSettle();
  }

  void assertRestricted(WidgetTester tester) {
    final context = tester.element(find.byType(PendingInvitationScreen));
    expect(context.read<VehicleProvider?>(), isNull);
    expect(context.read<DeviceStatusProvider?>(), isNull);
    expect(context.read<EventProvider?>(), isNull);
    expect(context.read<DeviceRepository?>(), isNull);
    expect(context.read<EventRepository?>(), isNull);
    expect(events.reads, isEmpty);
    expect(devices.reads, isEmpty);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('PRIVATE-OWNER'), findsNothing);
  }

  Future<void> lookup(
    WidgetTester tester, [
    String reference = 'vehicle-test',
  ]) async {
    await tester.enterText(find.byType(TextField), reference);
    await tester.tap(find.text('Consultar invitación'));
    await tester.pump();
  }
}

void main() {
  testWidgets(
    'acceptance waits for confirmed relation and late reply cannot undo revocation',
    (tester) async {
      final h = _Harness(contact);
      final changes = StreamController<ContactRelationResolution>.broadcast(
        sync: true,
      );
      addTearDown(changes.close);
      h.statusReader = (_) => changes.stream;
      final pending = Completer<void>();
      var calls = 0;
      h.operations = FirebaseContactOperations(
        perform: (action, ref, target) async {
          expect(action, 'accept');
          expect(ref, 'vehicle-test');
          expect(target, isNull);
          calls++;
          await pending.future;
        },
      );
      await h.mount(tester);
      await h.restricted(tester);
      await h.lookup(tester);
      changes.add((loading: false, status: 'pending'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar invitaci\u00f3n'));
      await tester.pump();
      expect(calls, 1);
      expect(find.textContaining('Relaci\u00f3n activa.'), findsNothing);
      changes.add((loading: false, status: 'active'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Relaci\u00f3n activa.'), findsOneWidget);
      changes.add((loading: false, status: 'revoked'));
      await tester.pumpAndSettle();
      pending.completeError(StateError('late acceptance response'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('La autorizaci\u00f3n fue revocada'),
        findsOneWidget,
      );
      expect(find.text('Aceptar invitaci\u00f3n'), findsNothing);
      h.assertRestricted(tester);
    },
  );

  testWidgets(
    'late failed acceptance after UID change does not restore old invitation',
    (tester) async {
      final h = _Harness(contact);
      final pending = Completer<void>();
      h.operations = FirebaseContactOperations(
        perform: (_, _, _) => pending.future,
      );
      await h.mount(tester);
      await h.restricted(tester);
      await h.lookup(tester);
      h.invitations['vehicle-test']!.add((loading: false, pending: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar invitaci\u00f3n'));
      await tester.pump();
      h.auth.change(
        const UserModel(id: 'new-user', name: 'New', email: 'new@example.test'),
      );
      await tester.pump();
      await tester.pump();
      await h.restricted(tester);
      pending.completeError(StateError('late failure'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se pudo confirmar la operaci\u00f3n'),
        findsNothing,
      );
      expect(find.text('Aceptar invitaci\u00f3n'), findsNothing);
      h.assertRestricted(tester);
    },
  );

  testWidgets(
    'owner revokes pending contact after confirmation and waits for RTDB',
    (tester) async {
      final h = _Harness(owner);
      final contacts = StreamController<Map<String, String>>.broadcast(
        sync: true,
      );
      addTearDown(contacts.close);
      h.ownerContactsReader = (_) => contacts.stream;
      final pending = Completer<void>();
      var calls = 0;
      h.operations = FirebaseContactOperations(
        perform: (action, ref, target) async {
          expect(action, 'revoke');
          expect(ref, 'vehicle-test');
          expect(target, 'contact-test');
          calls++;
          await pending.future;
        },
      );
      await h.mount(tester);
      h.vehicles.streams[owner.id]!.add(vehicle);
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(HomeScreen))).push('/contacts');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      contacts.add({'contact-test': 'pending'});
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revocar'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.text('Revocar').last);
      await tester.pump();
      expect(calls, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('pending'), findsOneWidget);
      contacts.add({'contact-test': 'revoked'});
      await tester.pumpAndSettle();
      expect(find.text('revoked'), findsOneWidget);
      expect(find.text('Revocar'), findsNothing);
    },
  );

  testWidgets('existing Login signs a contact into the restricted entry', (
    tester,
  ) async {
    final h = _Harness(null);
    await h.mount(tester);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'contact@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'fake-password');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Comprobando tu relación de acceso…'), findsOneWidget);
    await h.restricted(tester);
    h.assertRestricted(tester);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('failed sign-out clears local access and displays an error', (
    tester,
  ) async {
    final h = _Harness(contact);
    await h.mount(tester);
    await h.restricted(tester);
    h.auth.signOutError = StateError('sign-out failed');
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No se pudo comprobar tu acceso'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    h.assertRestricted(tester);
  });

  testWidgets('a vehicle belonging to another UID never confirms ownership', (
    tester,
  ) async {
    final h = _Harness(contact);
    await h.mount(tester);
    h.vehicles.streams[contact.id]!.add(vehicle);
    await tester.pumpAndSettle();
    h.assertRestricted(tester);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'late login error after leaving Login does not update a disposed form',
    (tester) async {
      final h = _Harness(null);
      await h.mount(tester);
      await tester.pumpAndSettle();
      h.auth.pendingSignIn = Completer<UserModel>();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'contact@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'fake-password');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      h.auth.changes.addError(StateError('profile unavailable'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsNothing);
      h.auth.pendingSignIn!.completeError(StateError('late read failure'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      h.assertRestricted(tester);
    },
  );

  testWidgets(
    'owner lookup pending does not mount owner providers; confirmed owner keeps navigation',
    (tester) async {
      final h = _Harness(owner);
      await h.mount(tester);
      expect(find.text('Comprobando tu relación de acceso…'), findsOneWidget);
      h.assertRestricted(tester);
      h.vehicles.streams[owner.id]!.add(vehicle);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(h.events.reads, ['owner-test/vehicle-test']);
      expect(h.devices.reads, ['SDA-TEST']);
      for (final label in ['Alertas', 'Vehículo', 'Historial', 'Perfil']) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(find.byType(PendingInvitationScreen), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending contact uses only restricted invitation and logout', (
    tester,
  ) async {
    final h = _Harness(contact);
    await h.mount(tester);
    await h.restricted(tester);
    h.assertRestricted(tester);
    await h.lookup(tester);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.textContaining('No hay una invitación pendiente'),
      findsNothing,
    );
    h.invitations['vehicle-test']!.add((loading: true, pending: false));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    h.invitations['vehicle-test']!.add((loading: false, pending: true));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Tienes una invitación pendiente'),
      findsOneWidget,
    );
    expect(h.references, ['vehicle-test']);
    h.assertRestricted(tester);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(h.invitations['vehicle-test']!.hasListener, isFalse);
  });

  testWidgets(
    'missing relationship and direct owner routes never grant access',
    (tester) async {
      final h = _Harness(contact);
      await h.mount(tester);
      await h.restricted(tester);
      final router = GoRouter.of(
        tester.element(find.byType(PendingInvitationScreen)),
      );
      for (final path in [
        '/home',
        '/alerts',
        '/vehicle',
        '/history',
        '/profile',
        '/contacts',
        '/incident/test',
        '/emergency/active',
        '/login',
        '/register',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/access');
        h.assertRestricted(tester);
      }
      await h.lookup(tester);
      h.invitations['vehicle-test']!.add((loading: false, pending: false));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No hay una invitación pendiente confirmada'),
        findsOneWidget,
      );
      h.assertRestricted(tester);
    },
  );

  testWidgets(
    'owner read errors differ from absence and loading and keep providers blocked',
    (tester) async {
      final h = _Harness(contact);
      await h.mount(tester);
      h.vehicles.streams[contact.id]!.addError(StateError('unavailable'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se pudo comprobar tu acceso'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      h.assertRestricted(tester);
      await tester.tap(find.text('Reintentar comprobación'));
      await tester.pump();
      expect(find.text('Comprobando tu relación de acceso…'), findsOneWidget);
      await h.restricted(tester);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets(
    'invitation error and edited reference remove the previous result',
    (tester) async {
      final h = _Harness(contact);
      await h.mount(tester);
      await h.restricted(tester);
      await h.lookup(tester);
      h.invitations['vehicle-test']!.add((loading: false, pending: true));
      await tester.pumpAndSettle();
      h.invitations['vehicle-test']!.addError(StateError('read failed'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se pudo consultar la invitación'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tienes una invitación pendiente'),
        findsNothing,
      );
      await tester.enterText(find.byType(TextField), 'other-reference');
      await tester.pump();
      expect(h.invitations['vehicle-test']!.hasListener, isFalse);
      h.invitations['vehicle-test']!.add((loading: false, pending: true));
      await tester.pump();
      expect(
        find.textContaining('Tienes una invitación pendiente'),
        findsNothing,
      );
      h.assertRestricted(tester);
    },
  );

  testWidgets(
    'UID change disposes owner providers and ignores late old vehicle data',
    (tester) async {
      final h = _Harness(owner);
      await h.mount(tester);
      h.vehicles.streams[owner.id]!.add(vehicle);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      h.auth.change(contact);
      await tester.pump();
      await tester.pump();
      await h.restricted(tester);
      final context = tester.element(find.byType(PendingInvitationScreen));
      expect(context.read<EventProvider?>(), isNull);
      expect(context.read<VehicleProvider?>(), isNull);
      expect(context.read<DeviceStatusProvider?>(), isNull);
      expect(h.vehicles.streams[owner.id]!.hasListener, isFalse);
      h.vehicles.streams[owner.id]!.add(vehicle);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsNothing);
      expect(h.events.reads, ['owner-test/vehicle-test']);
    },
  );

  testWidgets(
    'profile/session error does not route to owner or invitation form',
    (tester) async {
      final h = _Harness(contact);
      await h.mount(tester);
      h.auth.changes.addError(StateError('profile unavailable'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se pudo comprobar tu acceso'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      h.assertRestricted(tester);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'changing restricted UID clears the reference and pending message',
    (tester) async {
      final h = _Harness(contact);
      await h.mount(tester);
      await h.restricted(tester);
      await h.lookup(tester);
      h.invitations['vehicle-test']!.add((loading: false, pending: true));
      await tester.pumpAndSettle();
      h.auth.change(
        const UserModel(
          id: 'other-test',
          name: 'Other',
          email: 'other@example.test',
        ),
      );
      await tester.pump();
      await tester.pump();
      await h.restricted(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        find.textContaining('Tienes una invitación pendiente'),
        findsNothing,
      );
      expect(h.invitations['vehicle-test']!.hasListener, isFalse);
      h.assertRestricted(tester);
    },
  );
}
