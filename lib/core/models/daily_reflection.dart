import 'mizan_enums.dart';

class DailyReflection {
  const DailyReflection({
    required this.date,
    required this.mainGoalCompleted,
    required this.energyLevel,
    required this.mood,
    required this.achievement,
    required this.difficulty,
    required this.lesson,
    required this.tomorrowAdjustment,
  });

  final DateTime date;
  final bool mainGoalCompleted;
  final EnergyLevel energyLevel;
  final MoodLevel mood;
  final String achievement;
  final String difficulty;
  final String lesson;
  final String tomorrowAdjustment;
}
