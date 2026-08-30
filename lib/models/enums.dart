enum GoalStatus { notStarted, inProgress, done, parked }

extension GoalStatusX on GoalStatus {
  String get label => switch (this) {
        GoalStatus.notStarted => 'Not started',
        GoalStatus.inProgress => 'In progress',
        GoalStatus.done => 'Done',
        GoalStatus.parked => 'Parked',
      };

  bool get isLive => this == GoalStatus.inProgress;

  static GoalStatus fromKey(String key) => GoalStatus.values
      .firstWhere((s) => s.name == key, orElse: () => GoalStatus.notStarted);
}

/// The three training sub-views. Running is flat on screen (one activity
/// per workout); strength and skills nest exercises.
enum WorkoutType { strength, running, skills, conditioning }

extension WorkoutTypeX on WorkoutType {
  String get label => switch (this) {
        WorkoutType.strength => 'Strength',
        WorkoutType.running => 'Running',
        WorkoutType.skills => 'Skills',
        WorkoutType.conditioning => 'HYROX',
      };

  bool get isNested => this != WorkoutType.running;

  /// Strength and skills progress per exercise, so their charts follow the
  /// exercise wherever it was logged. Running and HYROX are whole-session
  /// efforts, so theirs follow the workout.
  bool get chartsByExercise =>
      this == WorkoutType.strength || this == WorkoutType.skills;

  /// Time-based events: a smaller number is a better one.
  bool get lowerIsBetter =>
      this == WorkoutType.running || this == WorkoutType.conditioning;

  /// What the progression chart plots for this type.
  String get metricLabel => switch (this) {
        WorkoutType.strength => 'Top set',
        WorkoutType.running => 'Pace',
        WorkoutType.skills => 'Max reps',
        WorkoutType.conditioning => 'Time',
      };

  String get metricUnit => switch (this) {
        WorkoutType.strength => 'kg',
        WorkoutType.running => '/km',
        WorkoutType.skills => 'reps',
        WorkoutType.conditioning => '',
      };

  static WorkoutType fromKey(String key) => WorkoutType.values
      .firstWhere((t) => t.name == key, orElse: () => WorkoutType.strength);
}

/// Carried over from the Notion Tasks database. Optional everywhere — a
/// quick-add capture has no priority until you give it one.
enum Priority { high, medium, low }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.high => 'High',
        Priority.medium => 'Medium',
        Priority.low => 'Low',
      };

  /// Lower sorts first.
  int get rank => index;

  static Priority? fromKey(Object? key) {
    if (key is! String) return null;
    for (final p in Priority.values) {
      if (p.name == key) return p;
    }
    return null;
  }
}
