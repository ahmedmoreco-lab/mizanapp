import 'package:flutter_test/flutter_test.dart';
import 'package:soulping_care/core/models/mizan_enums.dart';
import 'package:soulping_care/core/models/wake_up_assessment.dart';
import 'package:soulping_care/features/today/providers/daily_plan_provider.dart';

void main() {
  test('wake-up answers refresh the plan deterministically', () {
    final provider = DailyPlanProvider(
      clock: () => DateTime(2026, 7, 18, 8),
    );

    provider.applyWakeUpAssessment(
      const WakeUpAssessment(
        sleepQuality: SleepQuality.good,
        energyLevel: EnergyLevel.high,
        dayType: DayType.workday,
        trainingPlan: TrainingPlan.training,
      ),
    );

    expect(provider.isWorkday, isTrue);
    expect(provider.energyLevel, EnergyLevel.high);
    expect(provider.plan.priorityTasks.first.estimatedMinutes, 75);
  });

  test('Work Mode recommendation advances after completion and skip', () {
    final provider = DailyPlanProvider(
      clock: () => DateTime(2026, 7, 16, 8),
    );
    final first = provider.nextRecommendedTask!;

    provider.completeTask(first.id);
    final second = provider.nextRecommendedTask!;
    provider.skipTask(second.id);

    expect(second.id, isNot(first.id));
    expect(provider.nextRecommendedTask!.id, isNot(second.id));
    expect(provider.plan.completionPercentage, greaterThan(0));
  });
}
