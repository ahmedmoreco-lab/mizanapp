import 'enums.dart';

/// The exercise library. Names are unique; deleting one that has history
/// is blocked in the repository — rename or archive instead, so a chart
/// is never silently erased.
class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.type,
    this.isTracked = false,
    this.isArchived = false,
    this.lastUsedAt,
  });

  final String id;
  final String name;
  final WorkoutType type;

  /// The lift currently plotted in the progression chart for its type.
  final bool isTracked;
  final bool isArchived;
  final DateTime? lastUsedAt;

  Exercise copyWith({
    String? name,
    WorkoutType? type,
    bool? isTracked,
    bool? isArchived,
    DateTime? lastUsedAt,
  }) =>
      Exercise(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        isTracked: isTracked ?? this.isTracked,
        isArchived: isArchived ?? this.isArchived,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'is_tracked': isTracked,
        'is_archived': isArchived,
        'last_used_at': lastUsedAt?.millisecondsSinceEpoch,
      };

  static Exercise fromJson(Map<String, Object?> r) => Exercise(
        id: r['id']! as String,
        name: r['name']! as String,
        type: WorkoutTypeX.fromKey(r['type']! as String),
        isTracked: (r['is_tracked'] as bool?) ?? false,
        isArchived: (r['is_archived'] as bool?) ?? false,
        lastUsedAt: r['last_used_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['last_used_at']! as int),
      );
}
