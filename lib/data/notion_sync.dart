/// Merging a Notion export into the tasks the app already holds.
///
/// The bundled snapshot import replaces everything it touches. That is correct for
/// first launch and wrong for every launch after it — re-running it now
/// would clear the tasks you captured here. This merges instead.
///
/// The split is by id. Tasks that came from Notion carry an id derived
/// from their Notion page (`task-<first 16 hex of the page id>`); tasks
/// captured in the app carry a uuid. So the app can always tell which
/// side owns a row, and the two never collide.
///
/// Notion owns the content of its own tasks: title, pillar, priority,
/// due date and notes. The app owns completion — done is sticky, so
/// ticking something off here is never undone by a later sync. Nothing
/// is ever deleted: a task that has vanished from Notion stays put, on
/// the principle that a sync should not be able to destroy work.
///
/// Goals are not synced, so the link from a task to a goal stays with
/// the app. Taking it from the payload would clear every link the
/// original import made the first time a sync ran without one.
library;

import 'dart:convert';

import '../models/task.dart';



const notionIdPrefix = 'task-';

/// Whether this id belongs to a task that originated in Notion.
bool isNotionOwned(String id) => id.startsWith(notionIdPrefix);

/// The app-side id for a Notion page id, however it is spelled — with
/// dashes, without, or as a full URL.
String notionTaskId(String pageIdOrUrl) {
  // Take the last 32-hex run rather than every hex character in the
  // string: a bare "strip non-hex" pass would harvest the a and c out
  // of "app.notion.com" and shift the whole id, so every task would
  // arrive as a stranger and be added again instead of updated.
  final compact = pageIdOrUrl.toLowerCase().replaceAll('-', '');
  final ids = RegExp(r'[0-9a-f]{32}').allMatches(compact).toList();
  if (ids.isEmpty) {
    throw FormatException('Not a Notion page id: $pageIdOrUrl');
  }
  return '$notionIdPrefix${ids.last.group(0)!.substring(0, 16)}';
}

class NotionMergeResult {
  const NotionMergeResult({
    required this.tasks,
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.appOnly,
    required this.missingFromNotion,
  });

  /// The merged task list, ready to replace the app's own.
  final List<Task> tasks;

  final int added;
  final int updated;
  final int unchanged;

  /// Tasks captured in the app, which a sync never touches.
  final int appOnly;

  /// Notion-owned tasks the payload did not mention. Kept, not deleted.
  final int missingFromNotion;

  bool get changedAnything => added > 0 || updated > 0;

  String get summary {
    if (!changedAnything) return 'Already up to date.';
    final parts = <String>[
      if (added > 0) '$added added',
      if (updated > 0) '$updated updated',
    ];
    return '${parts.join(', ')}.';
  }
}

/// Merge [incoming] Notion tasks into [existing].
///
/// Order is preserved: existing tasks keep their position, new ones are
/// appended. Nothing is removed.
NotionMergeResult mergeNotionTasks({
  required List<Task> existing,
  required List<Task> incoming,
}) {
  final fromNotion = <String, Task>{
    for (final t in incoming)
      if (isNotionOwned(t.id)) t.id: t,
  };

  final merged = <Task>[];
  var updated = 0;
  var unchanged = 0;
  var appOnly = 0;
  var missing = 0;
  final seen = <String>{};

  for (final current in existing) {
    if (!isNotionOwned(current.id)) {
      // Captured in the app. Not Notion's to change.
      merged.add(current);
      appOnly++;
      continue;
    }

    final update = fromNotion[current.id];
    if (update == null) {
      // Gone from Notion, or simply outside the exported view. Keep it.
      merged.add(current);
      missing++;
      continue;
    }

    seen.add(current.id);
    final next = _apply(current, update);
    merged.add(next);
    if (_differs(current, next)) {
      updated++;
    } else {
      unchanged++;
    }
  }

  var added = 0;
  for (final t in incoming) {
    if (!isNotionOwned(t.id) || seen.contains(t.id)) continue;
    if (existing.any((e) => e.id == t.id)) continue;
    merged.add(t);
    added++;
  }

  return NotionMergeResult(
    tasks: merged,
    added: added,
    updated: updated,
    unchanged: unchanged,
    appOnly: appOnly,
    missingFromNotion: missing,
  );
}

/// Notion's content over the app's, except for completion.
Task _apply(Task current, Task update) {
  // Done is sticky: finished in either place means finished. Whichever
  // side completed it first keeps the timestamp, so a sync cannot move
  // a completion date around under you.
  final done = current.done || update.done;
  DateTime? completedAt;
  if (done) {
    completedAt = current.done
        ? (current.completedAt ?? update.completedAt)
        : (update.completedAt ?? DateTime.now());
  }

  return Task(
    id: current.id,
    title: update.title,
    pillar: update.pillar,
    // Not from the payload: goals are not synced, so a payload without
    // one must not unfile a task from its goal.
    goalId: current.goalId,
    isTodayFocus: update.isTodayFocus,
    done: done,
    priority: update.priority,
    dueDate: update.dueDate,
    notes: update.notes,
    // The app's record of when it first saw the task. Notion's own
    // created time would rewrite history on every sync.
    createdAt: current.createdAt,
    completedAt: completedAt,
  );
}

bool _differs(Task a, Task b) =>
    a.title != b.title ||
    a.pillar != b.pillar ||
    a.goalId != b.goalId ||
    a.isTodayFocus != b.isTodayFocus ||
    a.done != b.done ||
    a.priority != b.priority ||
    a.dueDate != b.dueDate ||
    a.notes != b.notes ||
    a.completedAt != b.completedAt;

/// Parse a sync payload: the same shape as the bundled snapshot, so one
/// exporter serves both. Only `tasks` is read — goals are not synced.
List<Task> parseNotionTasks(String raw) {
  final text = raw.trim();
  if (text.isEmpty) throw const FormatException('Nothing to read.');

  final decoded = jsonDecode(text);
  final List<Object?> rows;
  if (decoded is Map) {
    final tasks = decoded['tasks'];
    if (tasks is! List) {
      throw const FormatException('No "tasks" list in that payload.');
    }
    rows = tasks;
  } else if (decoded is List) {
    rows = decoded;
  } else {
    throw const FormatException('Expected an object or a list.');
  }

  return rows
      .map((e) => Task.fromJson(Map<String, Object?>.from(e as Map)))
      .toList();
}
