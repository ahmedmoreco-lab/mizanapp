import 'package:flutter_test/flutter_test.dart';
import 'package:soulping_care/core/models/mizan_enums.dart';
import 'package:soulping_care/core/services/mock_daily_plan_service.dart';

void main() {
  const service = MockDailyPlanService();
  final now = DateTime(2026, 7, 16, 8);

  test('generates a deterministic three-task workday plan', () {
    final plan = service.generateDailyPlan(
      now: now,
      profile: MockDailyPlanService.mockAhmed,
      isWorkday: true,
      trainingPlan: TrainingPlan.training,
      energyLevel: EnergyLevel.high,
    );

    expect(plan.priorityTasks, hasLength(3));
    expect(plan.priorityTasks.first.id, 'meaningful-work');
    expect(plan.priorityTasks.first.estimatedMinutes, 75);
    expect(plan.mealDirection.title, 'Fuel a training day');
    expect(plan.completionPercentage, 0);
  });

  test('low-energy free day protects energy', () {
    final plan = service.generateDailyPlan(
      now: now,
      profile: MockDailyPlanService.mockAhmed,
      isWorkday: false,
      trainingPlan: TrainingPlan.rest,
      energyLevel: EnergyLevel.low,
    );

    expect(plan.mainGoal, contains('Protect your energy'));
    expect(plan.priorityTasks.first.id, 'personal-project');
    expect(plan.suggestedActivity, contains('gentle'));
  });
}
