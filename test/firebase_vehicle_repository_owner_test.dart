import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/repositories/firebase/firebase_device_repository.dart';
import 'package:smartroad/repositories/firebase/firebase_vehicle_repository.dart';
import 'package:smartroad/state/device_status_provider.dart';
import 'package:smartroad/state/vehicle_provider.dart';

class _Database extends Fake implements FirebaseDatabase {
  final streams = <String, StreamController<DatabaseEvent>>{};

  @override
  DatabaseReference ref([String? path]) => _Reference(this, path ?? '');

  void emit(String path, Object? value) {
    streams[path]!.add(_Event(value));
  }

  Future<void> close() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class _Reference extends Fake implements DatabaseReference {
  final _Database database;
  @override
  final String path;
  final String? filter;

  _Reference(this.database, this.path, [this.filter]);

  @override
  DatabaseReference child(String childPath) => _Reference(database, '$path/$childPath');

  @override
  Query orderByChild(String childPath) => _Reference(database, path, childPath);

  @override
  Query equalTo(Object? value, {String? key}) => _Reference(database, path, 'ownerId=$value');

  @override
  Stream<DatabaseEvent> get onValue => database.streams
      .putIfAbsent(filter == null ? path : '$path/$filter', () => StreamController<DatabaseEvent>())
      .stream;
}

class _Event extends Fake implements DatabaseEvent {
  final Object? value;
  _Event(this.value);

  @override
  DataSnapshot get snapshot => _Snapshot(value);
}

class _Snapshot extends Fake implements DataSnapshot {
  @override
  final Object? value;
  _Snapshot(this.value);
}

const _owned = {
  'ownerId': 'owner',
  'deviceId': 'SDA-TEST',
  'brand': 'Test',
  'model': 'Model',
  'plate': 'TEST',
};

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  test('owner resolves only the indexed vehicle and its SDA', () async {
    final database = _Database();
    final provider = VehicleProvider(FirebaseVehicleRepository(database: database));
    provider.setUserId('owner');
    database.emit('users/owner/ownerVehicleId', 'owned');
    await _tick();
    database.emit('vehicles/ownerId=owner', {'owned': _owned});
    await _tick();
    expect(provider.vehicle?.id, 'owned');
    expect(provider.vehicle?.deviceId, 'SDA-TEST');
    provider.dispose();
    await database.close();
  });

  test('no owner relation does not query or assign a vehicle', () async {
    final database = _Database();
    final provider = VehicleProvider(FirebaseVehicleRepository(database: database));
    provider.setUserId('contact');
    database.emit('users/contact/ownerVehicleId', null);
    await _tick();
    expect(provider.vehicle, isNull);
    expect(database.streams, isNot(contains('vehicles/ownerId=contact')));
    provider.dispose();
    await database.close();
  });

  test('contradictory, ambiguous and malformed relations do not select a first row', () async {
    final database = _Database();
    final provider = VehicleProvider(FirebaseVehicleRepository(database: database));
    provider.setUserId('owner');
    database.emit('users/owner/ownerVehicleId', 'owned');
    await _tick();

    database.emit('vehicles/ownerId=owner', {'other': _owned});
    await _tick();
    expect(provider.vehicle, isNull);

    database.emit('vehicles/ownerId=owner', {'owned': _owned, 'other': _owned});
    await _tick();
    expect(provider.vehicle, isNull);

    database.emit('vehicles/ownerId=owner', {'owned': {..._owned, 'ownerId': 'other'}});
    await _tick();
    expect(provider.vehicle, isNull);

    database.emit('vehicles/ownerId=owner', {'owned': {..._owned, 'deviceId': ''}});
    await _tick();
    expect(provider.vehicle, isNull);

    database.emit('vehicles/ownerId=owner', {'owned': _owned});
    await _tick();
    expect(provider.vehicle?.id, 'owned');

    database.emit('users/owner/ownerVehicleId', null);
    await _tick();
    expect(provider.vehicle, isNull);
    provider.dispose();
    await database.close();
  });

  test('read failure clears a previously resolved vehicle', () async {
    final database = _Database();
    final provider = VehicleProvider(FirebaseVehicleRepository(database: database));
    provider.setUserId('owner');
    database.emit('users/owner/ownerVehicleId', 'owned');
    await _tick();
    database.emit('vehicles/ownerId=owner', {'owned': _owned});
    await _tick();
    expect(provider.vehicle?.id, 'owned');

    database.streams['vehicles/ownerId=owner']!.addError(StateError('read denied'));
    await _tick();
    expect(provider.vehicle, isNull);
    provider.dispose();
    await database.close();
  });

  test('SDA read failure clears the previously visible status', () async {
    final database = _Database();
    final provider = DeviceStatusProvider(FirebaseDeviceRepository(database: database));
    provider.setDeviceId('SDA-TEST');
    database.emit('devices/SDA-TEST', {'online': true});
    await _tick();
    expect(provider.status?.online, isTrue);

    database.streams['devices/SDA-TEST']!.addError(StateError('read denied'));
    await _tick();
    expect(provider.status, isNull);
    provider.dispose();
    await database.close();
  });
}
