import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Everything the app owns, as one JSON document.
///
/// v1 is deliberately local-first: no account, no network, no native
/// database plugin, so the same build runs on Windows, Chrome, Android
/// and iOS with nothing to install. The shape below is the schema from
/// the design handoff; moving it to SQLite or Supabase later means
/// replacing this file, not the models above it.
class LocalStore {
  static const _key = 'ahmed_os_document_v1';

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

  Future<void> save(Map<String, Object?> document) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(document));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Pretty-printed copy for the Export everything setting.
  String exportJson(Map<String, Object?> document) =>
      const JsonEncoder.withIndent('  ').convert(document);
}
