import 'dart:async';

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

  static const _networkTimeout = Duration(seconds: 12);

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
    try {
      await _reference.set({
        'schemaVersion': 1,
        'updatedAt': FieldValue.serverTimestamp(),
        'document': document,
      }).timeout(_networkTimeout);
      await _clearPendingOperation();
      _setStatus(SyncStatus.synced);
    } on FirebaseException {
      _setStatus(SyncStatus.offline);
    } on TimeoutException {
      _setStatus(SyncStatus.offline);
    }
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
    } on FirebaseException {
      _setStatus(SyncStatus.offline);
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
    if (!_disposed && _syncStatus.value != status) {
      _syncStatus.value = status;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _local.dispose();
    _legacy.dispose();
    _syncStatus.dispose();
  }
}
