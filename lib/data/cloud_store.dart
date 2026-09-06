import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_store.dart';

class CloudUnavailableException implements Exception {
  const CloudUnavailableException();

  @override
  String toString() =>
      'Cloud data is unavailable and this device has no cache.';
}

/// Local-first storage mirrored to one Firestore document per account.
class CloudStore implements DocumentStore {
  CloudStore({
    required FirebaseFirestore firestore,
    required User user,
    LocalStore? legacyStore,
  })  : _user = user,
        _local = LocalStore.forUser(user.uid),
        _legacy = legacyStore ?? LocalStore(),
        _reference = firestore
            .collection('users')
            .doc(user.uid)
            .collection('state')
            .doc('app');

  final User _user;
  final LocalStore _local;
  final LocalStore _legacy;
  final DocumentReference<Map<String, dynamic>> _reference;
  final ValueNotifier<SyncStatus> _syncStatus =
      ValueNotifier(SyncStatus.syncing);
  final ValueNotifier<String?> _syncMessage = ValueNotifier(null);

  static const _networkTimeout = Duration(seconds: 12);

  /// Firestore refuses any document over 1 MiB. Stopping short of that
  /// leaves room for the envelope and for the write to be explained
  /// rather than simply rejected.
  static const _documentSizeLimit = 900 * 1024;

  /// Codes that mean "the connection failed" rather than "the server said
  /// no". Everything else is a refusal that retrying will not fix.
  static const _retryableCodes = <String>{
    'unavailable',
    'deadline-exceeded',
    'cancelled',
    'aborted',
    'internal',
    'unknown',
  };

  bool _cloudReady = false;
  bool _disposed = false;
  String? _pendingOperation;

  String get _pendingKey => 'ahmed_os_sync_pending_${_user.uid}';

  @override
  String? get accountEmail => _user.email;

  @override
  bool get isCloudBacked => true;

  @override
  ValueListenable<SyncStatus> get syncStatus => _syncStatus;

  @override
  ValueListenable<String?> get syncMessage => _syncMessage;

  @override
  Stream<Map<String, Object?>> get changes async* {
    try {
      await for (final snapshot in _reference.snapshots()) {
        if (_disposed) {
          continue;
        }

        _cloudReady = true;
        if (_pendingOperation == 'delete') {
          await _deleteCloud();
          continue;
        }
        if (_pendingOperation == 'save') {
          final localDocument = await _local.load();
          if (localDocument.isNotEmpty) await _writeCloud(localDocument);
          continue;
        }
        if (!snapshot.exists) continue;

        final document = _extractDocument(snapshot.data());
        if (document.isEmpty) continue;
        await _local.save(document);
        _setStatus(SyncStatus.synced);
        yield document;
      }
    } on FirebaseException {
      _setStatus(SyncStatus.offline);
    }
  }

  @override
  Future<Map<String, Object?>> load() async {
    final localDocument = await _local.load();
    _pendingOperation = await _readPendingOperation();
    _setStatus(SyncStatus.syncing);

    try {
      final snapshot = await _reference
          .get(const GetOptions(source: Source.server))
          .timeout(_networkTimeout);
      _cloudReady = true;

      if (_pendingOperation == 'delete') {
        await _deleteCloud();
        return <String, Object?>{};
      }

      if (_pendingOperation == 'save' && localDocument.isNotEmpty) {
        await _writeCloud(localDocument);
        return localDocument;
      }

      if (snapshot.exists) {
        final cloudDocument = _extractDocument(snapshot.data());
        await _local.save(cloudDocument);
        _setStatus(SyncStatus.synced);
        return cloudDocument;
      }

      if (localDocument.isNotEmpty) {
        await save(localDocument);
        return localDocument;
      } else {
        final legacyDocument = await _legacy.load();
        if (legacyDocument.isNotEmpty) {
          await save(legacyDocument);
          await _legacy.clear();
          return legacyDocument;
        }
      }
      _setStatus(SyncStatus.synced);
      return localDocument;
    } on FirebaseException {
      return _loadOffline(localDocument);
    } on TimeoutException {
      return _loadOffline(localDocument);
    }
  }

  @override
  Future<void> save(Map<String, Object?> document) async {
    await _local.save(document);
    await _setPendingOperation('save');
    if (!_cloudReady) {
      _setStatus(SyncStatus.offline);
      return;
    }
    await _writeCloud(document);
  }

  Future<void> _writeCloud(Map<String, Object?> document) async {
    _setStatus(SyncStatus.syncing);

    // Catch the size ceiling before the server does, so it reads as a
    // real problem with a real number instead of a silent failure to sync.
    final bytes = utf8.encode(jsonEncode(document)).length;
    if (bytes > _documentSizeLimit) {
      _reject(
        'Your data is ${(bytes / 1024).round()} KB and Firestore caps one '
        'document at 1024 KB. Everything is still saved on this device, but '
        'it can no longer sync. Export a copy, then split the training log '
        'out of the main document.',
      );
      return;
    }

    try {
      await _reference.set({
        'schemaVersion': 1,
        'updatedAt': FieldValue.serverTimestamp(),
        'document': document,
      }).timeout(_networkTimeout);
      await _clearPendingOperation();
      _setStatus(SyncStatus.synced);
      _syncMessage.value = null;
    } on FirebaseException catch (error) {
      _handleFirebaseError(error, 'save');
    } on TimeoutException {
      _setStatus(SyncStatus.offline);
    }
  }

  /// A dropped connection and a refused write look the same from the
  /// outside and are not the same problem: one clears itself, the other
  /// never will.
  void _handleFirebaseError(FirebaseException error, String action) {
    if (_retryableCodes.contains(error.code)) {
      _setStatus(SyncStatus.offline);
      return;
    }
    _reject(switch (error.code) {
      'permission-denied' =>
        'Firestore refused the $action. Check that the security rules are '
            'deployed and that you are signed in to the right account.',
      'resource-exhausted' =>
        'Firebase quota reached, so the $action was refused. It should '
            'resolve when the quota resets.',
      'invalid-argument' =>
        'Firestore rejected the $action as invalid — most likely the '
            'document has grown past its 1 MB limit.',
      _ => 'Firestore refused the $action (${error.code}). '
          'Your data is still saved on this device.',
    });
  }

  void _reject(String message) {
    _syncMessage.value = message;
    _setStatus(SyncStatus.rejected);
  }

  @override
  Future<void> clear() async {
    await _local.clear();
    await _setPendingOperation('delete');
    if (!_cloudReady) {
      _setStatus(SyncStatus.offline);
      return;
    }
    await _deleteCloud();
  }

  @override
  String exportJson(Map<String, Object?> document) =>
      _local.exportJson(document);

  Map<String, Object?> _extractDocument(Map<String, dynamic>? envelope) {
    final document = envelope?['document'];
    if (document is! Map) return <String, Object?>{};
    return Map<String, Object?>.from(document);
  }

  Future<Map<String, Object?>> _loadOffline(
    Map<String, Object?> localDocument,
  ) async {
    _cloudReady = false;
    _setStatus(SyncStatus.offline);
    if (localDocument.isNotEmpty) return localDocument;
    if (_pendingOperation == 'delete') return <String, Object?>{};

    final legacyDocument = await _legacy.load();
    if (legacyDocument.isEmpty) throw const CloudUnavailableException();
    await _local.save(legacyDocument);
    await _setPendingOperation('save');
    await _legacy.clear();
    return legacyDocument;
  }

  Future<void> _deleteCloud() async {
    _setStatus(SyncStatus.syncing);
    try {
      await _reference.delete().timeout(_networkTimeout);
      await _clearPendingOperation();
      _setStatus(SyncStatus.synced);
      _syncMessage.value = null;
    } on FirebaseException catch (error) {
      _handleFirebaseError(error, 'delete');
    } on TimeoutException {
      _setStatus(SyncStatus.offline);
    }
  }

  Future<String?> _readPendingOperation() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_pendingKey);
  }

  Future<void> _setPendingOperation(String operation) async {
    _pendingOperation = operation;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingKey, operation);
  }

  Future<void> _clearPendingOperation() async {
    _pendingOperation = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingKey);
  }

  void _setStatus(SyncStatus status) {
    if (_disposed) return;
    if (status != SyncStatus.rejected) _syncMessage.value = null;
    if (_syncStatus.value != status) _syncStatus.value = status;
  }

  @override
  void dispose() {
    _disposed = true;
    _local.dispose();
    _legacy.dispose();
    _syncStatus.dispose();
    _syncMessage.dispose();
  }
}
