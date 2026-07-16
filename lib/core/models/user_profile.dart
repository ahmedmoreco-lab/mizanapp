import 'package:flutter/material.dart';

import 'mizan_enums.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.preferredLanguage,
    required this.normalWakeTime,
    required this.normalSleepTime,
    required this.workStartTime,
    required this.workEndTime,
    required this.goals,
    required this.interests,
    required this.dietaryPreferences,
    required this.activityLevel,
  });

  final String id;
  final String name;
  final AppLanguage preferredLanguage;
  final TimeOfDay normalWakeTime;
  final TimeOfDay normalSleepTime;
  final TimeOfDay workStartTime;
  final TimeOfDay workEndTime;
  final List<String> goals;
  final List<String> interests;
  final List<DietaryPreference> dietaryPreferences;
  final ActivityLevel activityLevel;
}
