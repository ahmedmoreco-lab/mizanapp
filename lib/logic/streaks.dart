import '../models/workout.dart';

class TrainingStats {
  const TrainingStats({
    required this.currentStreak,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
    required this.weekDays,
  });

  final int currentStreak;
  final int thisWeek;
  final int thisMonth;
  final int total;

  /// Monday → Sunday, true where a workout was logged.
  final List<bool> weekDays;

  static const empty = TrainingStats(
    currentStreak: 0,
    thisWeek: 0,
    thisMonth: 0,
    total: 0,
    weekDays: [false, false, false, false, false, false, false],
  );
}

TrainingStats computeTrainingStats(List<Workout> workouts, {DateTime? now}) {
  final today = _midnight(now ?? DateTime.now());
  final logged = <DateTime>{};
  var total = 0;

  for (final w in workouts) {
    if (w.isTemplate || w.date == null) continue;
    total++;
    logged.add(_midnight(w.date!));
  }
  if (total == 0) return TrainingStats.empty;

  // A streak that has not been broken yet still counts while today is
  // young, so start from today and fall back to yesterday.
  var cursor = logged.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  var streak = 0;
  while (logged.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final monday = today.subtract(Duration(days: today.weekday - 1));
  final weekDays = List<bool>.generate(
    7,
    (i) => logged.contains(monday.add(Duration(days: i))),
  );

  final thisWeek = workouts
      .where((w) =>
          !w.isTemplate &&
          w.date != null &&
          !_midnight(w.date!).isBefore(monday) &&
          !_midnight(w.date!).isAfter(today))
      .length;

  final thisMonth = workouts
      .where((w) =>
          !w.isTemplate &&
          w.date != null &&
          w.date!.year == today.year &&
          w.date!.month == today.month)
      .length;

  return TrainingStats(
    currentStreak: streak,
    thisWeek: thisWeek,
    thisMonth: thisMonth,
    total: total,
    weekDays: weekDays,
  );
}

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
