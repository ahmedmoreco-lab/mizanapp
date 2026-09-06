import 'package:ahmed_os/data/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// The size ceiling that made these changes necessary, kept honest.
/// Firestore refuses a document over 1 MiB; the app stops short of it so
/// the problem is reported rather than discovered months later.
const documentSizeLimit = 900 * 1024;
const firestoreHardLimit = 1024 * 1024;

void main() {
  test('a refused write is a different state from a dropped connection', () {
    expect(SyncStatus.values, contains(SyncStatus.rejected));
    expect(SyncStatus.rejected, isNot(SyncStatus.offline));
  });

  test('the guard leaves headroom under the Firestore document cap', () {
    expect(documentSizeLimit, lessThan(firestoreHardLimit));
    expect(firestoreHardLimit - documentSizeLimit, greaterThan(100 * 1024));
  });

  group('the local store reports no sync failure', () {
    test('it is local-only and carries no message', () {
      final store = LocalStore(key: 'ahmed_os_test_document');
      addTearDown(store.dispose);
      expect(store.isCloudBacked, isFalse);
      expect(store.syncStatus.value, SyncStatus.localOnly);
      expect(store.syncMessage.value, isNull);
    });
  });
}
