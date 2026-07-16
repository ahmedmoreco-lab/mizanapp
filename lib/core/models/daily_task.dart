import 'mizan_enums.dart';

class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedMinutes,
    required this.status,
    required this.category,
    this.scheduledTime,
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final int estimatedMinutes;
  final TaskStatus status;
  final TaskCategory category;
  final DateTime? scheduledTime;

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    int? estimatedMinutes,
    TaskStatus? status,
    TaskCategory? category,
    DateTime? scheduledTime,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }
}
