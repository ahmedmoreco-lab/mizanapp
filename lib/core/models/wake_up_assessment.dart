import 'mizan_enums.dart';

class WakeUpAssessment {
  const WakeUpAssessment({
    required this.sleepQuality,
    required this.energyLevel,
    required this.dayType,
    required this.trainingPlan,
  });

  final SleepQuality sleepQuality;
  final EnergyLevel energyLevel;
  final DayType dayType;
  final TrainingPlan trainingPlan;
}
