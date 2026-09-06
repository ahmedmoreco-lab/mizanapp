import '../models/pillar.dart';
import '../models/task.dart';
import '../models/workout.dart';

/// One suggested pillar, carrying the rule that surfaced it.
///
/// The reason is not decoration: a suggestion whose logic you can read is
/// a suggestion you can trust or overrule. A silent ranking gets ignored.
class FocusSuggestion {
  const FocusSuggestion({
    required this.pillar,
    required this.reason,
    required this.score,
  });

  final Pillar pillar;
  final String reason;
  final double score;
}

class FocusEngine {
  const FocusEngine({
    this.overdueWeight = 3.0,
    this.dueTodayWeight = 2.0,
    this.neglectWeight = 0.5,
    this.neglectCapDays = 21,
    this.minSuggestions = 3,
    this.maxSuggestions = 5,
    this.targetSuggestions = 4,
  });

  final double overdueWeight;
  final double dueTodayWeight;
  final double neglectWeight;
  final int neglectCapDays;
  final int minSuggestions;
  final int maxSuggestions;
  final int targetSuggestions;

  /// [eligible] is the set of pillars switched on in Profile → Pillars.
  List<FocusSuggestion> suggest({
    required Set<Pillar> eligible,
    required List<Task> tasks,
    required List<Workout> workouts,
    DateTime? now,
  }) {
    final today = _midnight(now ?? DateTime.now());
    if (eligible.isEmpty) return const [];

    final lastTouched = lastTouchedByPillar(tasks, workouts);

    final gaps = <Pillar, int?>{};
    for (final p in eligible) {
      final last = lastTouched[p];
      gaps[p] = last == null ? null : today.difference(last).inDays;
    }

    // The longest real gap, used to label one suggestion honestly.
    int? longest;
    for (final g in gaps.values) {
      if (g == null) continue;
      if (longest == null || g > longest) longest = g;
    }
    final anyNeverTouched = gaps.values.any((g) => g == null);

    final out = <FocusSuggestion>[];
    for (final p in eligible) {
      final open = tasks.where((t) => !t.done && t.pillar == p).toList();
      final overdue = open.where((t) => t.isOverdue).length;
      final dueToday = open.where((t) => t.isDueToday).length;
      final gap = gaps[p];

      final neglect = gap == null
          ? neglectCapDays.toDouble()
          : (gap > neglectCapDays ? neglectCapDays : gap).toDouble();

      final score = overdue * overdueWeight +
          dueToday * dueTodayWeight +
          neglect * neglectWeight;

      if (score <= 0) continue;

      out.add(FocusSuggestion(
        pillar: p,
        score: score,
        reason: _reason(
          overdue: overdue,
          dueToday: dueToday,
          gap: gap,
          longest: longest,
          anyNeverTouched: anyNeverTouched,
          openCount: open.length,
        ),
      ));
    }

    out.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.pillar.index.compareTo(b.pillar.index);
    });

    final want = out.length < minSuggestions
        ? out.length
        : (out.length < targetSuggestions ? out.length : targetSuggestions);
    return out.take(want.clamp(0, maxSuggestions)).toList();
  }

  String _reason({
    required int overdue,
    required int dueToday,
    required int? gap,
    required int? longest,
    required bool anyNeverTouched,
    required int openCount,
  }) {
    if (overdue > 0) {
      return overdue == 1 ? '1 task overdue' : '$overdue tasks overdue';
    }
    if (dueToday > 0) {
      return dueToday == 1 ? '1 task due today' : '$dueToday tasks due today';
    }
    if (gap == null) {
      return anyNeverTouched ? 'Nothing logged here yet' : 'No activity on record';
    }
    final base = gap == 0
        ? 'Touched earlier today'
        : gap == 1
            ? 'Untouched since yesterday'
            : 'Untouched for $gap days';
    if (longest != null && gap == longest && gap > 1) {
      return '$base — longest gap';
    }
    if (openCount > 0) {
      return '$base · $openCount open';
    }
    return base;
  }
}

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);


/// How long a pillar has gone untouched. The Home screen shows the worst
/// one or two as a single line — the whole of what the pillar cards used
/// to say, at a fraction of the space.
class PillarNeglect {
  const PillarNeglect({required this.pillar, required this.days});

  final Pillar pillar;

  /// Days since anything happened, or null if nothing ever has.
  final int? days;

  bool get never => days == null;
}

/// The most recent day each pillar saw activity: a task completed, or a
/// workout logged. Templates never count as training.
Map<Pillar, DateTime> lastTouchedByPillar(
  List<Task> tasks,
  List<Workout> workouts,
) {
  final touched = <Pillar, DateTime>{};
  void touch(Pillar pillar, DateTime? when) {
    if (when == null) return;
    final day = _midnight(when);
    final existing = touched[pillar];
    if (existing == null || day.isAfter(existing)) touched[pillar] = day;
  }

  for (final task in tasks) {
    final pillar = task.pillar;
    if (pillar == null) continue;
    touch(pillar, task.completedAt);
  }
  for (final workout in workouts) {
    if (workout.isTemplate) continue;
    touch(Pillar.training, workout.date);
  }
  return touched;
}

/// Worst gap first. Only pillars switched on in Profile are considered —
/// an aspirational pillar reporting a forty-day silence every morning is
/// exactly the noise this is meant to avoid.
List<PillarNeglect> pillarNeglect({
  required Set<Pillar> eligible,
  required List<Task> tasks,
  required List<Workout> workouts,
  DateTime? now,
}) {
  if (eligible.isEmpty) return const [];
  final today = _midnight(now ?? DateTime.now());
  final touched = lastTouchedByPillar(tasks, workouts);

  final out = <PillarNeglect>[
    for (final pillar in eligible)
      PillarNeglect(
        pillar: pillar,
        days: touched[pillar] == null
            ? null
            : today.difference(touched[pillar]!).inDays,
      ),
  ];

  out.sort((a, b) {
    if (a.never != b.never) return a.never ? -1 : 1;
    if (a.never && b.never) return a.pillar.index.compareTo(b.pillar.index);
    final c = b.days!.compareTo(a.days!);
    return c != 0 ? c : a.pillar.index.compareTo(b.pillar.index);
  });
  return out;
}
