import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatus { localOnly, syncing, synced, offline }

abstract interface class DocumentStore {
  String? get accountEmail;
  bool get isCloudBacked;
  ValueListenable<SyncStatus> get syncStatus;
  Stream<Map<String, Object?>> get changes;

  Future<Map<String, Object?>> load();
  Future<void> save(Map<String, Object?> document);
  Future<void> clear();
  String exportJson(Map<String, Object?> document);
  void dispose();
}

/// Device cache and the legacy persistence layer used before cloud sync.
class LocalStore implements DocumentStore {
  LocalStore({String key = legacyKey}) : _key = key;

  LocalStore.forUser(String uid) : _key = '${legacyKey}_$uid';

  static const legacyKey = 'ahmed_os_document_v1';

  final String _key;
  final ValueNotifier<SyncStatus> _syncStatus =
      ValueNotifier(SyncStatus.localOnly);

  @override
  String? get accountEmail => null;

  @override
  bool get isCloudBacked => false;

  @override
  ValueListenable<SyncStatus> get syncStatus => _syncStatus;

  @override
  Stream<Map<String, Object?>> get changes => const Stream.empty();

  @override
  Future<Map<String, Object?>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, Object?>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } on FormatException {
      // A corrupt document should not brick the app. Start clean and let
      // the user re-enter rather than crashing on every launch.
      return <String, Object?>{};
    }
    return <String, Object?>{};
  }

  @override
  Future<void> save(Map<String, Object?> document) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(document));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Pretty-printed copy for the Export everything setting.
  @override
  String exportJson(Map<String, Object?> document) =>
      const JsonEncoder.withIndent('  ').convert(document);

  @override
  void dispose() => _syncStatus.dispose();
}
