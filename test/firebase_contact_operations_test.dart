import 'package:flutter_test/flutter_test.dart';
import 'package:smartroad/repositories/firebase/firebase_contact_operations.dart';

void main() {
  for (final endpoint in ['', 'http://example.test', 'http://127.0.0.1:8080']) {
    test(
      'unconfigured or HTTP endpoint never obtains a Firebase token: $endpoint',
      () async {
        final operations = FirebaseContactOperations(endpoint: endpoint);
        expect(operations.available, isFalse);
        await expectLater(operations.accept('vehicle-test'), throwsStateError);
        await expectLater(
          operations.revoke('vehicle-test', 'contact-test'),
          throwsStateError,
        );
      },
    );
  }
}
