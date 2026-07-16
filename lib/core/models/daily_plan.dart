import 'daily_task.dart';
import 'meal_suggestion.dart';
import 'routine_item.dart';

class DailyPlan {
  const DailyPlan({
    required this.date,
    required this.mainGoal,
    required this.morningRoutineItems,
    required this.priorityTasks,
    required this.mealDirection,
    required this.suggestedActivity,
    required this.completionPercentage,
  });

  final DateTime date;
  final String mainGoal;
  final List<RoutineItem> morningRoutineItems;
  final List<DailyTask> priorityTasks;
  final MealSuggestion mealDirection;
  final String suggestedActivity;
  final double completionPercentage;

  DailyPlan copyWith({
    List<RoutineItem>? morningRoutineItems,
    List<DailyTask>? priorityTasks,
    double? completionPercentage,
  }) {
    return DailyPlan(
      date: date,
      mainGoal: mainGoal,
      morningRoutineItems: morningRoutineItems ?? this.morningRoutineItems,
      priorityTasks: priorityTasks ?? this.priorityTasks,
      mealDirection: mealDirection,
      suggestedActivity: suggestedActivity,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }
}
