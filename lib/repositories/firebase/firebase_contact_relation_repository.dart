import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';

/// Read-only contact relationship resolution, independent of provisioning.
/// Results describe current relationships, not permission to read canonical
/// incidents or SDA data. RTDB rules remain the security authority.
class FirebaseContactRelationRepository {
  final fb_auth.FirebaseAuth _auth;
  final DatabaseReference _usersRef;
  final DatabaseReference _contactsRef;

  FirebaseContactRelationRepository({
    fb_auth.FirebaseAuth? auth,
    FirebaseDatabase? database,
  }) : _auth = auth ?? fb_auth.FirebaseAuth.instance,
       _usersRef = (database ?? FirebaseDatabase.instance).ref('users'),
       _contactsRef = (database ?? FirebaseDatabase.instance).ref(
         'vehicleContacts',
       );

  /// Resolves only the signed-in user's pending invitation at an explicit
  /// vehicle reference. True means a proposal exists, never authorization.
  /// No vehicle, owner, SDA or incident data is read or returned.
  Stream<bool> watchPendingInvitation(String vehicleId) {
    if (!_isKey(vehicleId)) return Stream.value(false);

    late StreamController<(int, bool)> controller;
    StreamSubscription<fb_auth.User?>? authSubscription;
    StreamSubscription<DatabaseEvent>? relationSubscription;
    String? sessionUid;
    var sessionGeneration = 0;
    var resultVersion = 0;
    var cancelled = false;

    void emit(bool pending) => controller.add((++resultVersion, pending));

    void clearSession() {
      sessionGeneration++;
      sessionUid = null;
      relationSubscription?.cancel();
      relationSubscription = null;
      emit(false);
    }

    void followUser(fb_auth.User? user) {
      if (cancelled) return;
      final userId = user?.uid;
      if (userId == sessionUid &&
          relationSubscription != null &&
          _auth.currentUser?.uid == userId) {
        return;
      }
      clearSession();
      if (userId == null ||
          !_isKey(userId) ||
          _auth.currentUser?.uid != userId) {
        return;
      }
      sessionUid = userId;
      final currentSession = sessionGeneration;
      bool isCurrentSession() =>
          !cancelled &&
          currentSession == sessionGeneration &&
          _auth.currentUser?.uid == userId;

      relationSubscription = _contactsRef
          .child(vehicleId)
          .child(userId)
          .onValue
          .listen(
            (event) {
              if (!isCurrentSession()) return;
              final value = event.snapshot.value;
              emit(
                value is Map &&
                    value['status'] == 'pending' &&
                    value['activeFrom'] == null &&
                    value['revokedAt'] == null,
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!isCurrentSession()) return;
              emit(false);
              controller.addError(error, stackTrace);
            },
            onDone: () {
              if (isCurrentSession()) emit(false);
            },
          );
    }

    controller = StreamController<(int, bool)>(
      onListen: () {
        emit(false);
        authSubscription = _auth.authStateChanges().listen(
          followUser,
          onError: (Object error, StackTrace stackTrace) {
            clearSession();
            controller.addError(error, stackTrace);
          },
          onDone: () {
            clearSession();
            controller.close();
          },
        );
      },
      onCancel: () async {
        cancelled = true;
        sessionGeneration++;
        resultVersion++;
        await authSubscription?.cancel();
        await relationSubscription?.cancel();
      },
    );
    return controller.stream.map(
      (result) =>
          !cancelled &&
          result.$1 == resultVersion &&
          sessionUid == _auth.currentUser?.uid &&
          result.$2,
    );
  }

  /// Follows Firebase Authentication, including sign-out and UID changes.
  /// vehicleIds is only a discovery map; each candidate needs an active relation.
  Stream<Set<String>> watchAuthorizedVehicleIds() {
    late StreamController<(int, Set<String>)> controller;
    StreamSubscription<fb_auth.User?>? authSubscription;
    StreamSubscription<DatabaseEvent>? indexSubscription;
    final relations = <StreamSubscription<DatabaseEvent>>[];
    final authorized = <String>{};
    var generation = 0;
    var sessionGeneration = 0;
    String? sessionUid;
    var cancelled = false;

    void emit() => controller.add((
      sessionGeneration,
      Set<String>.unmodifiable(authorized),
    ));

    void reset() {
      generation++;
      for (final subscription in relations) {
        subscription.cancel();
      }
      relations.clear();
      authorized.clear();
      emit();
    }

    void clearSession() {
      sessionGeneration++;
      sessionUid = null;
      indexSubscription?.cancel();
      indexSubscription = null;
      reset();
    }

    void followUser(fb_auth.User? user) {
      if (cancelled) return;
      final userId = user?.uid;
      if (userId == sessionUid &&
          indexSubscription != null &&
          _auth.currentUser?.uid == userId) {
        return;
      }
      clearSession();
      if (userId == null ||
          !_isKey(userId) ||
          _auth.currentUser?.uid != userId) {
        return;
      }
      sessionUid = userId;
      final currentSession = sessionGeneration;
      bool isCurrentSession() =>
          !cancelled &&
          currentSession == sessionGeneration &&
          _auth.currentUser?.uid == userId;

      indexSubscription = _usersRef
          .child(userId)
          .child('vehicleIds')
          .onValue
          .listen(
            (event) {
              if (!isCurrentSession()) return;
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
                          if (!isCurrentSession() ||
                              generation != currentGeneration) {
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
                          if (!isCurrentSession() ||
                              generation != currentGeneration) {
                            return;
                          }
                          authorized.remove(vehicleId);
                          emit();
                          controller.addError(error, stackTrace);
                        },
                        onDone: () {
                          if (!isCurrentSession() ||
                              generation != currentGeneration) {
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
              if (!isCurrentSession()) return;
              reset();
              controller.addError(error, stackTrace);
            },
            onDone: () {
              if (!isCurrentSession()) return;
              reset();
            },
          );
    }

    controller = StreamController<(int, Set<String>)>(
      onListen: () {
        emit();
        authSubscription = _auth.authStateChanges().listen(
          followUser,
          onError: (Object error, StackTrace stackTrace) {
            clearSession();
            controller.addError(error, stackTrace);
          },
          onDone: () {
            clearSession();
            controller.close();
          },
        );
      },
      onCancel: () async {
        cancelled = true;
        sessionGeneration++;
        generation++;
        await authSubscription?.cancel();
        await indexSubscription?.cancel();
        await Future.wait(
          relations.map((subscription) => subscription.cancel()),
        );
      },
    );
    // A queued result must not outlive the session that produced it.
    return controller.stream.map(
      (result) =>
          result.$1 == sessionGeneration && sessionUid == _auth.currentUser?.uid
          ? result.$2
          : const <String>{},
    );
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
