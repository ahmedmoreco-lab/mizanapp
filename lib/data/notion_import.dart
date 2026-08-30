import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/goal.dart';
import '../models/pillar.dart';
import '../models/task.dart';

/// A one-off snapshot of the "HI Ahmed" Notion workspace, bundled as an
/// asset so the app opens with your real goals and tasks instead of an
/// empty shell.
///
/// This is a snapshot, not a sync. Notion and the app diverge from the
/// moment you edit either one — which is the point: the app is meant to
/// take over, not to mirror.
class NotionSnapshot {
  const NotionSnapshot({
    required this.goals,
    required this.tasks,
    required this.suggestingPillars,
    required this.source,
  });

  final List<Goal> goals;
  final List<Task> tasks;
  final Set<Pillar> suggestingPillars;
  final String source;

  bool get isEmpty => goals.isEmpty && tasks.isEmpty;

  static const assetPath = 'assets/data/notion_import.json';

  static Future<NotionSnapshot> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final doc = Map<String, Object?>.from(jsonDecode(raw) as Map);

    List<Map<String, Object?>> rows(Object? v) => ((v as List?) ?? const [])
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();

    final pillars = ((doc['suggesting_pillars'] as List?) ?? const [])
        .cast<String>()
        .map(PillarX.fromKey)
        .toSet();

    return NotionSnapshot(
      goals: rows(doc['goals']).map(Goal.fromJson).toList(),
      tasks: rows(doc['tasks']).map(Task.fromJson).toList(),
      suggestingPillars: pillars,
      source: (doc['source'] as String?) ?? 'Notion',
    );
  }
}
