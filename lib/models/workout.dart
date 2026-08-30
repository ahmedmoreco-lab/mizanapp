import 'enums.dart';
import 'set_entry.dart';

/// One exercise inside a workout, with its sets.
class WorkoutExercise {
  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.orderIndex,
    this.notes = '',
    List<SetEntry>? sets,
  }) : sets = sets ?? <SetEntry>[];

  final String id;
  final String exerciseId;
  final int orderIndex;
  final String notes;
  final List<SetEntry> sets;

  SetEntry? get topSet {
    SetEntry? best;
    for (final s in sets) {
      if (s.weightKg == null) continue;
      if (best == null || s.weightKg! > best.weightKg!) best = s;
    }
    return best;
  }

  int? get maxReps {
    int? best;
    for (final s in sets) {
      final r = s.reps;
      if (r == null) continue;
      if (best == null || r > best) best = r;
    }
    return best;
  }

  WorkoutExercise copyWith({
    int? orderIndex,
    String? notes,
    List<SetEntry>? sets,
  }) =>
      WorkoutExercise(
        id: id,
        exerciseId: exerciseId,
        orderIndex: orderIndex ?? this.orderIndex,
        notes: notes ?? this.notes,
        sets: sets ?? this.sets,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'exercise_id': exerciseId,
        'order_index': orderIndex,
        'notes': notes,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  static WorkoutExercise fromJson(Map<String, Object?> r) => WorkoutExercise(
        id: r['id']! as String,
        exerciseId: r['exercise_id']! as String,
        orderIndex: (r['order_index'] as int?) ?? 0,
        notes: (r['notes'] as String?) ?? '',
        sets: ((r['sets'] as List?) ?? const [])
            .map((e) => SetEntry.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
      );
}

/// A workout is the container. A template is the same shape with
/// [isTemplate] true and no date — which is why "save as template"
/// costs nothing to build.
class Workout {
  Workout({
    required this.id,
    required this.type,
    required this.title,
    this.date,
    this.durationMin,
    this.notes = '',
    this.templateId,
    this.isTemplate = false,
    required this.createdAt,
    List<WorkoutExercise>? exercises,
  }) : exercises = exercises ?? <WorkoutExercise>[];

  final String id;
  final WorkoutType type;
  final String title;
  final DateTime? date;
  final int? durationMin;
  final String notes;
  final String? templateId;
  final bool isTemplate;
  final DateTime createdAt;
  final List<WorkoutExercise> exercises;

  int get setCount => exercises.fold(0, (n, e) => n + e.sets.length);
  bool get hasAnySet => setCount > 0;

  Workout copyWith({
    String? title,
    WorkoutType? type,
    DateTime? date,
    int? durationMin,
    bool clearDuration = false,
    String? notes,
    String? templateId,
    bool? isTemplate,
    List<WorkoutExercise>? exercises,
  }) =>
      Workout(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        date: date ?? this.date,
        durationMin: clearDuration ? null : (durationMin ?? this.durationMin),
        notes: notes ?? this.notes,
        templateId: templateId ?? this.templateId,
        isTemplate: isTemplate ?? this.isTemplate,
        createdAt: createdAt,
        exercises: exercises ?? this.exercises,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'date': date?.millisecondsSinceEpoch,
        'duration_min': durationMin,
        'notes': notes,
        'template_id': templateId,
        'is_template': isTemplate,
        'created_at': createdAt.millisecondsSinceEpoch,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  static Workout fromJson(Map<String, Object?> r) => Workout(
        id: r['id']! as String,
        type: WorkoutTypeX.fromKey(r['type']! as String),
        title: (r['title'] as String?) ?? 'Workout',
        date: r['date'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['date']! as int),
        durationMin: r['duration_min'] as int?,
        notes: (r['notes'] as String?) ?? '',
        templateId: r['template_id'] as String?,
        isTemplate: (r['is_template'] as bool?) ?? false,
        createdAt: r['created_at'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
        exercises: ((r['exercises'] as List?) ?? const [])
            .map((e) =>
                WorkoutExercise.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
      );
}
