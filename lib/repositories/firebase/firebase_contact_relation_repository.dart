import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

/// Read-only contact relationship resolution, independent of provisioning.
/// Results describe current relationships, not permission to read canonical
/// incidents or SDA data. RTDB rules remain the security authority.
class FirebaseContactRelationRepository {
  final DatabaseReference _usersRef;
  final DatabaseReference _contactsRef;

  FirebaseContactRelationRepository({FirebaseDatabase? database})
    : _usersRef = (database ?? FirebaseDatabase.instance).ref('users'),
      _contactsRef = (database ?? FirebaseDatabase.instance).ref(
        'vehicleContacts',
      );

  /// [userId] must come from the authenticated session. vehicleIds is only
  /// a discovery map; every candidate needs its own active relationship.
  Stream<Set<String>> watchAuthorizedVehicleIds(String userId) {
    if (!_isKey(userId)) return Stream.value(const <String>{});

    late StreamController<Set<String>> controller;
    StreamSubscription<DatabaseEvent>? indexSubscription;
    final relations = <StreamSubscription<DatabaseEvent>>[];
    final authorized = <String>{};
    var generation = 0;
    var cancelled = false;

    void emit() => controller.add(Set<String>.unmodifiable(authorized));

    void reset() {
      generation++;
      for (final subscription in relations) {
        subscription.cancel();
      }
      relations.clear();
      authorized.clear();
      emit();
    }

    controller = StreamController<Set<String>>(
      onListen: () {
        emit();
        indexSubscription = _usersRef
            .child(userId)
            .child('vehicleIds')
            .onValue
            .listen(
              (event) {
                reset();
                final currentGeneration = generation;
                final index = event.snapshot.value;
                if (index is! Map) return;

                for (final entry in index.entries) {
                  final vehicleId = entry.key;
                  if (vehicleId is! String ||
                      !_isKey(vehicleId) ||
                      entry.value != true) {
                    continue;
                  }
                  relations.add(
                    _contactsRef
                        .child(vehicleId)
                        .child(userId)
                        .onValue
                        .listen(
                          (relationEvent) {
                            if (cancelled || generation != currentGeneration) {
                              return;
                            }
                            if (_isActive(relationEvent.snapshot.value)) {
                              authorized.add(vehicleId);
                            } else {
                              authorized.remove(vehicleId);
                            }
                            emit();
                          },
                          onError: (Object error, StackTrace stackTrace) {
                            if (cancelled || generation != currentGeneration) {
                              return;
                            }
                            authorized.remove(vehicleId);
                            emit();
                            controller.addError(error, stackTrace);
                          },
                          onDone: () {
                            if (cancelled || generation != currentGeneration) {
                              return;
                            }
                            authorized.remove(vehicleId);
                            emit();
                          },
                        ),
                  );
                }
              },
              onError: (Object error, StackTrace stackTrace) {
                reset();
                controller.addError(error, stackTrace);
              },
              onDone: () {
                reset();
                controller.close();
              },
            );
      },
      onCancel: () async {
        cancelled = true;
        generation++;
        await indexSubscription?.cancel();
        await Future.wait(
          relations.map((subscription) => subscription.cancel()),
        );
      },
    );
    return controller.stream;
  }

  // An active relationship has a start of validity and no revocation.
  // No comparison with device time or historical eligibility is made here.
  static bool _isActive(Object? value) {
    if (value is! Map ||
        value['status'] != 'active' ||
        value['revokedAt'] != null) {
      return false;
    }
    final activeFrom = value['activeFrom'];
    return activeFrom is num && activeFrom.isFinite && activeFrom >= 0;
  }

  static bool _isKey(String value) =>
      value.trim().isNotEmpty &&
      !RegExp(r'[.#$\[\]/\x00-\x1f\x7f]').hasMatch(value);
}
