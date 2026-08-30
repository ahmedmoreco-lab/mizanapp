import 'enums.dart';
import 'pillar.dart';

class Goal {
  Goal({
    required this.id,
    required this.title,
    required this.pillar,
    required this.status,
    this.whyItMatters = '',
    this.measure = '',
    this.targetDate,
    required this.createdAt,
    this.statusChangedAt,
  });

  final String id;
  final String title;
  final Pillar pillar;
  final GoalStatus status;
  final String whyItMatters;
  final String measure;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime? statusChangedAt;

  Goal copyWith({
    String? title,
    Pillar? pillar,
    GoalStatus? status,
    String? whyItMatters,
    String? measure,
    DateTime? targetDate,
    bool clearTargetDate = false,
    DateTime? statusChangedAt,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      pillar: pillar ?? this.pillar,
      status: status ?? this.status,
      whyItMatters: whyItMatters ?? this.whyItMatters,
      measure: measure ?? this.measure,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      createdAt: createdAt,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'pillar': pillar.key,
        'status': status.name,
        'why_it_matters': whyItMatters,
        'measure': measure,
        'target_date': targetDate?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'status_changed_at': statusChangedAt?.millisecondsSinceEpoch,
      };

  static Goal fromJson(Map<String, Object?> r) => Goal(
        id: r['id']! as String,
        title: r['title']! as String,
        pillar: PillarX.fromKey(r['pillar']! as String),
        status: GoalStatusX.fromKey(r['status']! as String),
        whyItMatters: (r['why_it_matters'] as String?) ?? '',
        measure: (r['measure'] as String?) ?? '',
        targetDate: _date(r['target_date']),
        createdAt: _date(r['created_at']) ?? DateTime.now(),
        statusChangedAt: _date(r['status_changed_at']),
      );
}

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
