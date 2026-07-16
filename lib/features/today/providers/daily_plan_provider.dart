import 'package:flutter/foundation.dart';

import '../../../core/models/daily_plan.dart';
import '../../../core/models/daily_reflection.dart';
import '../../../core/models/daily_task.dart';
import '../../../core/models/mizan_enums.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/wake_up_assessment.dart';
import '../../../core/services/mock_daily_plan_service.dart';

class DailyPlanProvider extends ChangeNotifier {
  DailyPlanProvider({
    MockDailyPlanService? service,
    DateTime Function()? clock,
    UserProfile? profile,
  })  : _service = service ?? const MockDailyPlanService(),
        _clock = clock ?? DateTime.now,
        profile = profile ?? MockDailyPlanService.mockAhmed {
    final now = _clock();
    _isWorkday =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    _plan = _buildPlan(now);
  }

  final MockDailyPlanService _service;
  final DateTime Function() _clock;
  final UserProfile profile;

  late DailyPlan _plan;
  late bool _isWorkday;
  EnergyLevel _energyLevel = EnergyLevel.medium;
  TrainingPlan _trainingPlan = TrainingPlan.undecided;
  WakeUpAssessment? _wakeUpAssessment;
  DailyReflection? _reflection;

  DailyPlan get plan => _plan;
  bool get isWorkday => _isWorkday;
  EnergyLevel get energyLevel => _energyLevel;
  TrainingPlan get trainingPlan => _trainingPlan;
  WakeUpAssessment? get wakeUpAssessment => _wakeUpAssessment;
  DailyReflection? get reflection => _reflection;

  DailyTask? get nextRecommendedTask {
    for (final task in _plan.priorityTasks) {
      if (task.status == TaskStatus.inProgress) return task;
    }
    for (final task in _plan.priorityTasks) {
      if (task.status == TaskStatus.pending) return task;
    }
    return null;
  }

  void applyWakeUpAssessment(WakeUpAssessment assessment) {
    _wakeUpAssessment = assessment;
    _energyLevel = assessment.energyLevel;
    _trainingPlan = assessment.trainingPlan;
    _isWorkday = assessment.dayType == DayType.workday;
    _plan = _buildPlan(_clock());
    notifyListeners();
  }

  void setRoutineCompleted(String id, bool completed) {
    final routines = _plan.morningRoutineItems
        .map((item) =>
            item.id == id ? item.copyWith(completed: completed) : item)
        .toList(growable: false);
    _plan = _plan.copyWith(morningRoutineItems: routines);
    _refreshCompletion();
  }

  void startTask(String id) => _setTaskStatus(id, TaskStatus.inProgress);

  void pauseTask(String id) => _setTaskStatus(id, TaskStatus.pending);

  void completeTask(String id) => _setTaskStatus(id, TaskStatus.completed);

  void skipTask(String id) => _setTaskStatus(id, TaskStatus.skipped);

  void saveReflection(DailyReflection reflection) {
    _reflection = reflection;
    _refreshCompletion();
  }

  DailyPlan _buildPlan(DateTime now) {
    return _service.generateDailyPlan(
      now: now,
      profile: profile,
      isWorkday: _isWorkday,
      trainingPlan: _trainingPlan,
      energyLevel: _energyLevel,
    );
  }

  void _setTaskStatus(String id, TaskStatus status) {
    final tasks = _plan.priorityTasks
        .map((task) => task.id == id ? task.copyWith(status: status) : task)
        .toList(growable: false);
    _plan = _plan.copyWith(priorityTasks: tasks);
    _refreshCompletion();
  }

  void _refreshCompletion() {
    final completedRoutines =
        _plan.morningRoutineItems.where((item) => item.completed).length;
    final completedTasks = _plan.priorityTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final reflectionPoints = _reflection == null ? 0 : 1;
    final total =
        _plan.morningRoutineItems.length + _plan.priorityTasks.length + 1;
    final completed = completedRoutines + completedTasks + reflectionPoints;
    _plan = _plan.copyWith(completionPercentage: completed / total);
    notifyListeners();
  }
}
