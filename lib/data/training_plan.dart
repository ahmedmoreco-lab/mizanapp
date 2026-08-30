import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/exercise.dart';
import '../models/workout.dart';

/// The current training cycle, bundled as an asset: the exercise library
/// and one template per session. Targets — sets, reps, load, cues — ride
/// along on each exercise so they are in front of you while you log.
class TrainingPlan {
  const TrainingPlan({
    required this.exercises,
    required this.templates,
    required this.name,
  });

  final List<Exercise> exercises;
  final List<Workout> templates;
  final String name;

  bool get isEmpty => exercises.isEmpty && templates.isEmpty;

  static const assetPath = 'assets/data/training_plan.json';

  static Future<TrainingPlan> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final doc = Map<String, Object?>.from(jsonDecode(raw) as Map);

    List<Map<String, Object?>> rows(Object? v) => ((v as List?) ?? const [])
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();

    return TrainingPlan(
      name: (doc['name'] as String?) ?? 'Training cycle',
      exercises: rows(doc['exercises']).map(Exercise.fromJson).toList(),
      templates: rows(doc['templates']).map(Workout.fromJson).toList(),
    );
  }
}
