import 'package:flutter/material.dart';

import '../models/daily_plan.dart';
import '../models/daily_task.dart';
import '../models/meal_suggestion.dart';
import '../models/mizan_enums.dart';
import '../models/routine_item.dart';
import '../models/user_profile.dart';

class MockDailyPlanService {
  const MockDailyPlanService();

  static const mockAhmed = UserProfile(
    id: 'local-ahmed',
    name: 'Ahmed',
    preferredLanguage: AppLanguage.english,
    normalWakeTime: TimeOfDay(hour: 6, minute: 30),
    normalSleepTime: TimeOfDay(hour: 22, minute: 30),
    workStartTime: TimeOfDay(hour: 9, minute: 0),
    workEndTime: TimeOfDay(hour: 16, minute: 0),
    goals: [
      'Complete meaningful work',
      'Train consistently',
      'Improve nutrition',
      'Continue learning',
    ],
    interests: [
      'Fitness',
      'Walking',
      'Reading',
      'Learning',
      'Business development',
    ],
    dietaryPreferences: [
      DietaryPreference.balanced,
      DietaryPreference.highProtein,
      DietaryPreference.halal,
    ],
    activityLevel: ActivityLevel.moderate,
  );

  DailyPlan generateDailyPlan({
    required DateTime now,
    required UserProfile profile,
    required bool isWorkday,
    required TrainingPlan trainingPlan,
    required EnergyLevel energyLevel,
  }) {
    final date = DateTime(now.year, now.month, now.day);
    final workStart = DateTime(
      now.year,
      now.month,
      now.day,
      profile.workStartTime.hour,
      profile.workStartTime.minute,
    );

    final mainGoal = switch ((isWorkday, energyLevel)) {
      (_, EnergyLevel.low) =>
        'Protect your energy and complete one meaningful task',
      (true, _) => 'Finish the highest-impact work before the day gets busy',
      (false, _) => 'Make steady progress on health and personal growth',
    };

    final routines = <RoutineItem>[
      const RoutineItem(
        id: 'hydrate',
        title: 'Drink water',
        category: RoutineCategory.hydration,
        estimatedMinutes: 2,
      ),
      const RoutineItem(
        id: 'reset',
        title: 'Take five calm breaths',
        category: RoutineCategory.mindfulness,
        estimatedMinutes: 3,
      ),
      RoutineItem(
        id: 'movement',
        title: energyLevel == EnergyLevel.low
            ? 'Do gentle mobility'
            : 'Stretch and move',
        category: RoutineCategory.movement,
        estimatedMinutes: energyLevel == EnergyLevel.low ? 5 : 10,
      ),
      const RoutineItem(
        id: 'plan',
        title: 'Review today’s main goal',
        category: RoutineCategory.planning,
        estimatedMinutes: 3,
      ),
    ];

    final focusMinutes = energyLevel == EnergyLevel.high ? 75 : 45;
    final tasks = isWorkday
        ? <DailyTask>[
            DailyTask(
              id: 'meaningful-work',
              title: 'Complete the highest-impact work item',
              description: 'Start with the outcome that matters most today.',
              priority: TaskPriority.high,
              estimatedMinutes: focusMinutes,
              status: TaskStatus.pending,
              category: TaskCategory.work,
              scheduledTime: workStart,
            ),
            DailyTask(
              id: 'business-development',
              title: 'Advance one business-development action',
              description:
                  'Send the message, draft the offer, or make the decision.',
              priority: TaskPriority.medium,
              estimatedMinutes: 30,
              status: TaskStatus.pending,
              category: TaskCategory.work,
              scheduledTime:
                  workStart.add(Duration(minutes: focusMinutes + 15)),
            ),
            DailyTask(
              id: 'health-session',
              title: _healthTaskTitle(trainingPlan),
              description: _healthTaskDescription(trainingPlan),
              priority: TaskPriority.medium,
              estimatedMinutes: trainingPlan == TrainingPlan.training ? 60 : 30,
              status: TaskStatus.pending,
              category: TaskCategory.health,
              scheduledTime: DateTime(now.year, now.month, now.day, 17, 30),
            ),
          ]
        : <DailyTask>[
            DailyTask(
              id: 'personal-project',
              title: 'Move a personal project forward',
              description: 'Choose one visible result you can finish today.',
              priority: TaskPriority.high,
              estimatedMinutes: focusMinutes,
              status: TaskStatus.pending,
              category: TaskCategory.personalGrowth,
              scheduledTime: DateTime(now.year, now.month, now.day, 10),
            ),
            DailyTask(
              id: 'learning',
              title: 'Complete a focused learning session',
              description: 'Read, practice, and capture one useful takeaway.',
              priority: TaskPriority.medium,
              estimatedMinutes: 30,
              status: TaskStatus.pending,
              category: TaskCategory.personalGrowth,
              scheduledTime: DateTime(now.year, now.month, now.day, 12),
            ),
            DailyTask(
              id: 'health-session',
              title: _healthTaskTitle(trainingPlan),
              description: _healthTaskDescription(trainingPlan),
              priority: TaskPriority.medium,
              estimatedMinutes: trainingPlan == TrainingPlan.training ? 60 : 35,
              status: TaskStatus.pending,
              category: TaskCategory.health,
              scheduledTime: DateTime(now.year, now.month, now.day, 17),
            ),
          ];

    final isTraining = trainingPlan == TrainingPlan.training;
    final meal = MealSuggestion(
      id: 'balanced-main-meal',
      title: isTraining ? 'Fuel a training day' : 'Build a steady-energy plate',
      description: isTraining
          ? 'Keep protein high and include enough carbohydrate around training.'
          : 'Choose a simple balanced meal that avoids an afternoon energy crash.',
      mealType: now.hour < 14 ? MealType.lunch : MealType.dinner,
      proteinGuidance: 'One to two palms of lean protein',
      carbohydrateGuidance:
          isTraining ? 'One to two cupped hands' : 'One cupped hand',
      vegetableGuidance: 'At least half the plate',
      fatGuidance: 'One thumb-sized serving',
      notes: 'Drink water and choose the simplest suitable option available.',
    );

    final suggestedActivity = switch ((energyLevel, now.hour)) {
      (EnergyLevel.low, _) => 'Take a gentle 15-minute walk',
      (_, < 17) =>
        'Use a free 20 minutes for reading or a short learning session',
      (_, _) => 'Take an outdoor walk and leave the phone in your pocket',
    };

    return DailyPlan(
      date: date,
      mainGoal: mainGoal,
      morningRoutineItems: routines,
      priorityTasks: tasks,
      mealDirection: meal,
      suggestedActivity: suggestedActivity,
      completionPercentage: 0,
    );
  }

  String _healthTaskTitle(TrainingPlan trainingPlan) {
    return switch (trainingPlan) {
      TrainingPlan.training => 'Complete today’s training session',
      TrainingPlan.rest => 'Take a restorative walk',
      TrainingPlan.undecided => 'Choose training or a restorative walk',
    };
  }

  String _healthTaskDescription(TrainingPlan trainingPlan) {
    return switch (trainingPlan) {
      TrainingPlan.training => 'Train with intention, then recover and refuel.',
      TrainingPlan.rest => 'Keep the pace easy and support recovery.',
      TrainingPlan.undecided =>
        'Decide after checking your energy this afternoon.',
    };
  }
}
