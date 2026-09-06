import 'package:ahmed_os/logic/focus_engine.dart';
import 'package:ahmed_os/logic/progress.dart';
import 'package:ahmed_os/logic/streaks.dart';
import 'package:ahmed_os/models/enums.dart';
import 'package:ahmed_os/models/pillar.dart';
import 'package:ahmed_os/models/set_entry.dart';
import 'package:ahmed_os/models/task.dart';
import 'package:ahmed_os/models/workout.dart';
import 'package:ahmed_os/ui/training/run_log_sheet.dart' show parseDuration;
import 'package:flutter_test/flutter_test.dart';

DateTime daysAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: n));
}

Task task({
  required String title,
  Pillar? pillar,
  String? goalId,
  bool done = false,
  DateTime? due,
  DateTime? completedAt,
}) =>
    Task(
      id: title,
      title: title,
      pillar: pillar,
      goalId: goalId,
      done: done,
      dueDate: due,
      completedAt: completedAt,
      createdAt: daysAgo(30),
    );

Workout strengthWorkout({
  required String id,
  required DateTime date,
  required String exerciseId,
  required List<double> weights,
}) =>
    Workout(
      id: id,
      type: WorkoutType.strength,
      title: id,
      date: date,
      createdAt: date,
      exercises: [
        WorkoutExercise(
          id: '$id-e',
          exerciseId: exerciseId,
          orderIndex: 0,
          sets: [
            for (var i = 0; i < weights.length; i++)
              SetEntry(id: '$id-s$i', setIndex: i + 1, weightKg: weights[i], reps: 5),
          ],
        ),
      ],
    );

void main() {
  group('FocusEngine', () {
    const engine = FocusEngine();

    test('only suggests pillars that are switched on', () {
      final out = engine.suggest(
        eligible: {Pillar.work, Pillar.training},
        tasks: [task(title: 'a', pillar: Pillar.content, due: daysAgo(3))],
        workouts: const [],
      );
      expect(out.every((s) => s.pillar != Pillar.content), isTrue);
    });

    test('overdue work outranks a long quiet gap', () {
      final out = engine.suggest(
        eligible: {Pillar.work, Pillar.faith},
        tasks: [
          task(title: 'late', pillar: Pillar.work, due: daysAgo(4)),
          task(
            title: 'prayed',
            pillar: Pillar.faith,
            done: true,
            completedAt: daysAgo(1),
          ),
        ],
        workouts: const [],
      );
      expect(out.first.pillar, Pillar.work);
      expect(out.first.reason, contains('overdue'));
    });

    test('every suggestion explains itself', () {
      final out = engine.suggest(
        eligible: {Pillar.work, Pillar.training, Pillar.faith},
        tasks: const [],
        workouts: const [],
      );
      expect(out, isNotEmpty);
      for (final s in out) {
        expect(s.reason.trim(), isNotEmpty);
      }
    });

    test('never returns more than the target number', () {
      final out = engine.suggest(
        eligible: Pillar.values.toSet(),
        tasks: const [],
        workouts: const [],
      );
      expect(out.length, lessThanOrEqualTo(4));
    });

    test('a workout counts as touching Training', () {
      final out = engine.suggest(
        eligible: {Pillar.training, Pillar.faith},
        tasks: const [],
        workouts: [
          strengthWorkout(
            id: 'w',
            date: daysAgo(0),
            exerciseId: 'squat',
            weights: const [100],
          ),
        ],
      );
      final training = out.where((s) => s.pillar == Pillar.training);
      final faith = out.where((s) => s.pillar == Pillar.faith);
      expect(faith, isNotEmpty);
      if (training.isNotEmpty) {
        expect(training.first.score, lessThan(faith.first.score));
      }
    });
  });

  group('pillar gaps', () {
    test('the worst gap comes first and never-touched leads', () {
      final gaps = pillarNeglect(
        eligible: {Pillar.work, Pillar.faith, Pillar.family},
        tasks: [
          task(
            title: 'w',
            pillar: Pillar.work,
            done: true,
            completedAt: daysAgo(1),
          ),
          task(
            title: 'f',
            pillar: Pillar.family,
            done: true,
            completedAt: daysAgo(6),
          ),
        ],
        workouts: const [],
      );
      expect(gaps.first.pillar, Pillar.faith);
      expect(gaps.first.never, isTrue);
      expect(gaps[1].pillar, Pillar.family);
      expect(gaps[1].days, 6);
      expect(gaps.last.pillar, Pillar.work);
      expect(gaps.last.days, 1);
    });

    test('a pillar switched off in settings is not reported', () {
      final gaps = pillarNeglect(
        eligible: {Pillar.work},
        tasks: const [],
        workouts: const [],
      );
      expect(gaps.map((g) => g.pillar), [Pillar.work]);
    });

    test('a logged workout counts as touching Training', () {
      final gaps = pillarNeglect(
        eligible: {Pillar.training},
        tasks: const [],
        workouts: [
          strengthWorkout(
            id: 'w',
            date: daysAgo(2),
            exerciseId: 'squat',
            weights: const [100],
          ),
        ],
      );
      expect(gaps.single.days, 2);
    });
  });

  group('training stats', () {
    test('counts consecutive days ending today', () {
      final stats = computeTrainingStats([
        strengthWorkout(id: 'a', date: daysAgo(0), exerciseId: 'x', weights: const [80]),
        strengthWorkout(id: 'b', date: daysAgo(1), exerciseId: 'x', weights: const [80]),
        strengthWorkout(id: 'c', date: daysAgo(2), exerciseId: 'x', weights: const [80]),
        strengthWorkout(id: 'd', date: daysAgo(9), exerciseId: 'x', weights: const [80]),
      ]);
      expect(stats.currentStreak, 3);
      expect(stats.total, 4);
    });

    test('templates never count as training', () {
      final stats = computeTrainingStats([
        Workout(
          id: 't',
          type: WorkoutType.strength,
          title: 'Push A',
          isTemplate: true,
          createdAt: daysAgo(1),
        ),
      ]);
      expect(stats.total, 0);
      expect(stats.currentStreak, 0);
    });
  });

  group('progress', () {
    test('goal progress counts only its own tasks', () {
      final p = goalProgress('g1', [
        task(title: '1', goalId: 'g1', done: true),
        task(title: '2', goalId: 'g1'),
        task(title: '3', goalId: 'g2', done: true),
      ]);
      expect(p.done, 1);
      expect(p.total, 2);
      expect(p.fraction, 0.5);
    });

    test('strength series plots the heaviest set per session', () {
      final series = buildSeries(
        workouts: [
          strengthWorkout(
              id: 'a', date: daysAgo(7), exerciseId: 'squat', weights: const [80, 85]),
          strengthWorkout(
              id: 'b', date: daysAgo(1), exerciseId: 'squat', weights: const [90, 87.5]),
        ],
        type: WorkoutType.strength,
        exerciseId: 'squat',
      );
      expect(series.points.map((p) => p.value).toList(), [85, 90]);
      expect(series.hasData, isTrue);
      expect(series.lowerIsBetter, isFalse);
    });

    test('a different lift is not plotted', () {
      final series = buildSeries(
        workouts: [
          strengthWorkout(
              id: 'a', date: daysAgo(2), exerciseId: 'bench', weights: const [70]),
        ],
        type: WorkoutType.strength,
        exerciseId: 'squat',
      );
      expect(series.points, isEmpty);
    });
  });

  group('conditioning and skill charting', () {
    Workout hyrox({required String id, required DateTime date, required int min}) =>
        Workout(
          id: id,
          type: WorkoutType.conditioning,
          title: 'HYROX',
          date: date,
          durationMin: min,
          createdAt: date,
        );

    test('HYROX charts session time, and faster is better', () {
      final series = buildSeries(
        workouts: [
          hyrox(id: 'a', date: daysAgo(14), min: 52),
          hyrox(id: 'b', date: daysAgo(1), min: 49),
        ],
        type: WorkoutType.conditioning,
        exerciseId: null,
      );
      expect(series.points.map((p) => p.value).toList(), [52 * 60, 49 * 60]);
      expect(series.lowerIsBetter, isTrue);
      expect(series.formatValue(49 * 60), '49:00');
    });

    test('a skill charts from inside a strength session', () {
      final saturday = Workout(
        id: 'sat',
        type: WorkoutType.strength,
        title: 'Push + Handstand',
        date: daysAgo(2),
        createdAt: daysAgo(2),
        exercises: [
          WorkoutExercise(
            id: 'we1',
            exerciseId: 'hspu',
            orderIndex: 0,
            sets: [SetEntry(id: 's1', setIndex: 1, reps: 4)],
          ),
          WorkoutExercise(
            id: 'we2',
            exerciseId: 'bench',
            orderIndex: 1,
            sets: [SetEntry(id: 's2', setIndex: 1, weightKg: 77.5, reps: 6)],
          ),
        ],
      );
      final skills = buildSeries(
        workouts: [saturday],
        type: WorkoutType.skills,
        exerciseId: 'hspu',
      );
      expect(skills.points.single.value, 4,
          reason: 'skill work must chart wherever it was logged');

      final strength = buildSeries(
        workouts: [saturday],
        type: WorkoutType.strength,
        exerciseId: 'bench',
      );
      expect(strength.points.single.value, 77.5);
    });

    test('with no exercise chosen a per-exercise chart stays empty', () {
      final series = buildSeries(
        workouts: [
          strengthWorkout(
              id: 'a', date: daysAgo(1), exerciseId: 'squat', weights: const [100]),
        ],
        type: WorkoutType.strength,
        exerciseId: null,
      );
      expect(series.points, isEmpty);
    });

    test('every workout type knows how it charts', () {
      expect(WorkoutType.strength.chartsByExercise, isTrue);
      expect(WorkoutType.skills.chartsByExercise, isTrue);
      expect(WorkoutType.running.chartsByExercise, isFalse);
      expect(WorkoutType.conditioning.chartsByExercise, isFalse);
      expect(WorkoutType.conditioning.lowerIsBetter, isTrue);
      expect(WorkoutType.strength.lowerIsBetter, isFalse);
    });
  });

  group('sets and runs', () {
    test('pace is derived from distance and duration', () {
      final entry = SetEntry(
        id: 's',
        setIndex: 1,
        distanceKm: 8,
        durationSec: 44 * 60,
      );
      expect(entry.paceSecPerKm, 330);
      expect(formatPace(entry.paceSecPerKm!), '5:30');
    });

    test('duration accepts mm:ss, h:mm:ss and plain minutes', () {
      expect(parseDuration('44:10'), 44 * 60 + 10);
      expect(parseDuration('1:04:20'), 3860);
      expect(parseDuration('45'), 45 * 60);
      expect(parseDuration(''), isNull);
      expect(parseDuration('nope'), isNull);
    });

    test('a strength set reads back the way it was logged', () {
      final entry = SetEntry(
          id: 's', setIndex: 1, weightKg: 92.5, reps: 5, rpe: 8);
      expect(entry.summary(), '92.5 kg × 5');
      final round = SetEntry.fromJson(entry.toJson());
      expect(round.weightKg, 92.5);
      expect(round.reps, 5);
      expect(round.rpe, 8);
    });

    test('a workout survives a JSON round trip', () {
      final w = strengthWorkout(
          id: 'w', date: daysAgo(1), exerciseId: 'squat', weights: const [100, 102.5]);
      final round = Workout.fromJson(w.toJson());
      expect(round.exercises.single.sets.length, 2);
      expect(round.exercises.single.topSet?.weightKg, 102.5);
      expect(round.setCount, 2);
      expect(round.hasAnySet, isTrue);
    });
  });

  group('task ordering', () {
    test('High outranks an undated Low, pinned outranks both', () {
      final a = task(title: 'low', pillar: Pillar.work)
          .copyWith(priority: Priority.low);
      final b = task(title: 'high', pillar: Pillar.work)
          .copyWith(priority: Priority.high);
      final c = task(title: 'pinned', pillar: Pillar.work)
          .copyWith(priority: Priority.low, isTodayFocus: true);
      final ranked = [a, b, c]..sort((x, y) {
          if (x.isTodayFocus != y.isTodayFocus) return x.isTodayFocus ? -1 : 1;
          final xp = x.priority?.rank ?? 99;
          final yp = y.priority?.rank ?? 99;
          return xp.compareTo(yp);
        });
      expect(ranked.map((t) => t.title).toList(), ['pinned', 'high', 'low']);
    });

    test('priority survives a JSON round trip', () {
      final t = task(title: 'x').copyWith(priority: Priority.medium);
      expect(Task.fromJson(t.toJson()).priority, Priority.medium);
      expect(Task.fromJson(t.copyWith(clearPriority: true).toJson()).priority,
          isNull);
    });
  });

  group('tasks', () {
    test('yesterday is overdue, today is not', () {
      expect(task(title: 'a', due: daysAgo(1)).isOverdue, isTrue);
      expect(task(title: 'b', due: daysAgo(0)).isOverdue, isFalse);
      expect(task(title: 'c', due: daysAgo(1), done: true).isOverdue, isFalse);
    });

    test('a quick-add task is a random task', () {
      expect(task(title: 'a').isRandom, isTrue);
      expect(task(title: 'b', pillar: Pillar.work).isRandom, isFalse);
    });
  });
}
