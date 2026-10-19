import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

/// No endpoint is configured by default. Production transport must be HTTPS.
class FirebaseContactOperations {
  final FirebaseAuth? auth;
  final String endpoint;
  final Future<void> Function(
    String action,
    String vehicleId,
    String? contactUid,
  )?
  perform;
  FirebaseContactOperations({
    this.auth,
    this.endpoint = const String.fromEnvironment('CONTACT_API_URL'),
    this.perform,
  });
  bool get available =>
      perform != null || Uri.tryParse(endpoint)?.scheme == 'https';
  Future<void> accept(String vehicleId) => _call('accept', vehicleId, null);
  Future<void> revoke(String vehicleId, String contactUid) =>
      _call('revoke', vehicleId, contactUid);
  Future<void> _call(
    String action,
    String vehicleId,
    String? contactUid,
  ) async {
    if (perform != null) {
      await perform!(action, vehicleId, contactUid);
      return;
    }
    final base = Uri.tryParse(endpoint);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw StateError('Secure contact endpoint unavailable');
    }
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final user = firebaseAuth.currentUser;
    if (user == null) throw StateError('Authentication required');
    final token = await user.getIdToken();
    if (token == null || firebaseAuth.currentUser?.uid != user.uid) {
      throw StateError('Session changed');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.postUrl(base.resolve('/contacts/$action'));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({'vehicleId': vehicleId, 'contactUid': ?contactUid}),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      await response.drain<void>().timeout(const Duration(seconds: 20));
      if (firebaseAuth.currentUser?.uid != user.uid) {
        throw StateError('Session changed');
      }
      if (response.statusCode != 200) {
        throw StateError('Contact operation unconfirmed');
      }
      // UI state comes only from RTDB, never from a late HTTP response.
    } finally {
      client.close(force: true);
    }
  }
}
