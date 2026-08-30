import 'dart:convert';
import 'dart:io';

import 'package:ahmed_os/models/enums.dart';
import 'package:ahmed_os/models/exercise.dart';
import 'package:ahmed_os/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Exercise> exercises;
  late List<Workout> templates;

  setUpAll(() {
    final raw = File('assets/data/training_plan.json').readAsStringSync();
    final doc = Map<String, Object?>.from(jsonDecode(raw) as Map);
    List<Map<String, Object?>> rows(Object? v) => (v! as List)
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();
    exercises = rows(doc['exercises']).map(Exercise.fromJson).toList();
    templates = rows(doc['templates']).map(Workout.fromJson).toList();
  });

  test('the cycle parses into real models', () {
    expect(exercises, hasLength(35));
    expect(templates, hasLength(7));
    expect(templates.every((t) => t.isTemplate), isTrue);
    expect(templates.every((t) => t.date == null), isTrue);
  });

  test('every template exercise exists in the library', () {
    final ids = exercises.map((e) => e.id).toSet();
    for (final t in templates) {
      expect(t.exercises, isNotEmpty, reason: t.title);
      for (final we in t.exercises) {
        expect(ids, contains(we.exerciseId), reason: '${t.title} / ${we.exerciseId}');
      }
    }
  });

  test('every exercise in a template carries its target', () {
    for (final t in templates) {
      for (final we in t.exercises) {
        expect(we.notes.trim(), isNotEmpty, reason: '${t.title} / ${we.exerciseId}');
      }
    }
  });

  test('skill work is typed as skills so it charts on its own', () {
    final skills = exercises.where((e) => e.type == WorkoutType.skills);
    expect(skills.map((e) => e.name), containsAll(<String>[
      'Freestanding handstand',
      'Strict HSPU',
      'Explosive high pull-up',
      'Feet-assisted low-bar transition',
    ]));
  });

  test('both HYROX versions are conditioning, and the sim has nine stations', () {
    final hyrox = templates.where((t) => t.type == WorkoutType.conditioning);
    expect(hyrox, hasLength(2));
    final sim = templates.firstWhere((t) => t.id == 'tpl-hyrox-sim');
    expect(sim.exercises, hasLength(9));
    // The 1 km legs repeat, and the model allows the same exercise more
    // than once in a session.
    final runs =
        sim.exercises.where((e) => e.exerciseId == 'ex-sim-run');
    expect(runs, hasLength(5));
  });

  test('order is preserved and unique within each template', () {
    for (final t in templates) {
      final order = t.exercises.map((e) => e.orderIndex).toList();
      expect(order, List<int>.generate(t.exercises.length, (i) => i),
          reason: t.title);
    }
  });

  test('exactly one tracked exercise per charted type', () {
    for (final type in [WorkoutType.strength, WorkoutType.skills]) {
      final tracked =
          exercises.where((e) => e.type == type && e.isTracked);
      expect(tracked, hasLength(1), reason: type.label);
    }
  });

  test('the removed movements are gone', () {
    final names = exercises.map((e) => e.name.toLowerCase()).join(' | ');
    expect(names, isNot(contains('leg press')));
    expect(names, isNot(contains('muscle-up negative')));
  });

  test('ids are unique', () {
    expect(exercises.map((e) => e.id).toSet(), hasLength(exercises.length));
    expect(templates.map((t) => t.id).toSet(), hasLength(templates.length));
  });
}
