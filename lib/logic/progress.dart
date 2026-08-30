import '../models/enums.dart';
import '../models/set_entry.dart';
import '../models/task.dart';
import '../models/workout.dart';

class GoalProgress {
  const GoalProgress({required this.done, required this.total});

  final int done;
  final int total;

  double get fraction => total == 0 ? 0 : done / total;
  String get label => '$done of $total ${total == 1 ? 'task' : 'tasks'}';
}

GoalProgress goalProgress(String goalId, List<Task> tasks) {
  final linked = tasks.where((t) => t.goalId == goalId).toList();
  return GoalProgress(
    done: linked.where((t) => t.done).length,
    total: linked.length,
  );
}

/// One plotted point: a workout date and the metric for that session.
class ChartPoint {
  const ChartPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

/// Series for the progression chart.
///
/// Strength plots the heaviest set of the chosen lift, skills plots its
/// best rep count, running plots pace in seconds per km (lower is better,
/// so the chart inverts it).
class ChartSeries {
  const ChartSeries({
    required this.points,
    required this.type,
    required this.lowerIsBetter,
  });

  final List<ChartPoint> points;
  final WorkoutType type;
  final bool lowerIsBetter;

  bool get hasData => points.length >= 2;
  ChartPoint? get latest => points.isEmpty ? null : points.last;

  String formatValue(double v) => switch (type) {
        WorkoutType.strength =>
          v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
        WorkoutType.skills => v.toStringAsFixed(0),
        WorkoutType.running => formatPace(v),
        WorkoutType.conditioning => formatClock(v.round()),
      };
}

ChartSeries buildSeries({
  required List<Workout> workouts,
  required WorkoutType type,
  required String? exerciseId,
}) {
  final points = <ChartPoint>[];

  // Strength and skills follow the lift, not the session it sat in — your
  // handstand work lives inside Saturday's push day and still has to chart.
  final byExercise = type.chartsByExercise;
  if (byExercise && exerciseId == null) {
    return ChartSeries(points: points, type: type, lowerIsBetter: type.lowerIsBetter);
  }

  final sessions = workouts
      .where((w) =>
          !w.isTemplate &&
          w.date != null &&
          (byExercise || w.type == type))
      .toList()
    ..sort((a, b) => a.date!.compareTo(b.date!));

  for (final w in sessions) {
    double? value;
    for (final we in w.exercises) {
      if (exerciseId != null && we.exerciseId != exerciseId) continue;
      if (type == WorkoutType.strength) {
        final top = we.topSet?.weightKg;
        if (top != null && (value == null || top > value)) value = top;
      } else if (type == WorkoutType.skills) {
        final best = we.maxReps?.toDouble();
        if (best != null && (value == null || best > value)) value = best;
      } else if (type == WorkoutType.running) {
        for (final s in we.sets) {
          final pace = s.paceSecPerKm;
          if (pace != null && (value == null || pace < value)) value = pace;
        }
      }
    }
    // A HYROX session is scored as one time, not per station.
    if (type == WorkoutType.conditioning) {
      // The session time is the score. Prefer the duration you set on the
      // workout; only fall back to summing station splits, because a
      // half-logged set of splits would read as a false personal best.
      var total = (w.durationMin ?? 0) * 60;
      if (total == 0) {
        for (final we in w.exercises) {
          for (final s in we.sets) {
            total += s.durationSec ?? 0;
          }
        }
      }
      if (total > 0) value = total.toDouble();
    }
    if (value != null) points.add(ChartPoint(date: w.date!, value: value));
  }

  return ChartSeries(
    points: points,
    type: type,
    lowerIsBetter: type.lowerIsBetter,
  );
}
