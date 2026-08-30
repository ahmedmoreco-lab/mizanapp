import 'enums.dart';
import 'pillar.dart';

class Task {
  Task({
    required this.id,
    required this.title,
    this.pillar,
    this.goalId,
    this.isTodayFocus = false,
    this.done = false,
    this.priority,
    this.dueDate,
    this.notes = '',
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;

  /// Null means the task was captured through quick-add and never filed.
  /// Capture first, categorise later or never.
  final Pillar? pillar;
  final String? goalId;
  final bool isTodayFocus;
  final bool done;
  final Priority? priority;
  final DateTime? dueDate;
  final String notes;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isRandom => pillar == null && goalId == null;

  bool get isOverdue {
    final d = dueDate;
    if (d == null || done) return false;
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);
    return d.isBefore(endOfToday) && !_sameDay(d, today);
  }

  bool get isDueToday => dueDate != null && _sameDay(dueDate!, DateTime.now());

  Task copyWith({
    String? title,
    Pillar? pillar,
    bool clearPillar = false,
    String? goalId,
    bool clearGoal = false,
    bool? isTodayFocus,
    bool? done,
    Priority? priority,
    bool clearPriority = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? notes,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      pillar: clearPillar ? null : (pillar ?? this.pillar),
      goalId: clearGoal ? null : (goalId ?? this.goalId),
      isTodayFocus: isTodayFocus ?? this.isTodayFocus,
      done: done ?? this.done,
      priority: clearPriority ? null : (priority ?? this.priority),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      notes: notes ?? this.notes,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'pillar': pillar?.key,
        'goal_id': goalId,
        'is_today_focus': isTodayFocus ? 1 : 0,
        'done': done ? 1 : 0,
        'priority': priority?.name,
        'due_date': dueDate?.millisecondsSinceEpoch,
        'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
      };

  static Task fromJson(Map<String, Object?> r) => Task(
        id: r['id']! as String,
        title: r['title']! as String,
        pillar: r['pillar'] == null ? null : PillarX.fromKey(r['pillar']! as String),
        goalId: r['goal_id'] as String?,
        isTodayFocus: (r['is_today_focus'] as int? ?? 0) == 1,
        done: (r['done'] as int? ?? 0) == 1,
        priority: PriorityX.fromKey(r['priority']),
        dueDate: _d(r['due_date']),
        notes: (r['notes'] as String?) ?? '',
        createdAt: _d(r['created_at']) ?? DateTime.now(),
        completedAt: _d(r['completed_at']),
      );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime? _d(Object? v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
