import 'mizan_enums.dart';

class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.estimatedMinutes,
    this.completed = false,
  });

  final String id;
  final String title;
  final RoutineCategory category;
  final int estimatedMinutes;
  final bool completed;

  RoutineItem copyWith({bool? completed}) {
    return RoutineItem(
      id: id,
      title: title,
      category: category,
      estimatedMinutes: estimatedMinutes,
      completed: completed ?? this.completed,
    );
  }
}
