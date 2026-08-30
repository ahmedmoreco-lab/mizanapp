import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../logic/progress.dart';
import '../../models/enums.dart';
import '../../models/exercise.dart';
import '../../models/pillar.dart';
import '../../models/workout.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'progress_chart.dart';
import 'run_log_sheet.dart';
import 'start_workout_sheet.dart';
import 'workout_page.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  WorkoutType _type = WorkoutType.strength;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final color = t.pillar(Pillar.training);

    final workouts = app.workoutsOfType(_type);
    final series = app.seriesFor(_type);
    final tracked = app.trackedExercise(_type);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x8, Sp.x20, Sp.x8),
            children: [
              const ScreenTitle('Training'),
              const SizedBox(height: Sp.x14),
              _TypeSegments(
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),

              const SizedBox(height: Sp.x24),
              _ChartHeader(
                type: _type,
                tracked: tracked,
                series: series,
                color: color,
                onPick: _type.chartsByExercise
                    ? () => _pickTrackedExercise(context)
                    : null,
              ),
              const SizedBox(height: Sp.x8),
              if (series.hasData)
                AppCard(
                  padding: const EdgeInsets.fromLTRB(
                      Sp.x14, Sp.x14, Sp.x14, Sp.x10),
                  child: Column(
                    children: [
                      ProgressChart(series: series, color: color),
                      const SizedBox(height: Sp.x8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('d MMM')
                                .format(series.points.first.date),
                            style: manrope(
                                size: 10, weight: 600, color: t.faint),
                          ),
                          Text(
                            DateFormat('d MMM').format(series.points.last.date),
                            style: manrope(
                                size: 10, weight: 600, color: t.faint),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                EmptyState(
                  title: workouts.isEmpty
                      ? 'Nothing logged yet'
                      : 'Not enough to draw a line',
                  message: workouts.isEmpty
                      ? 'Start a session from one of your templates. Three or four entries is enough to see a line.'
                      : _type == WorkoutType.conditioning
                          ? 'One more session with a duration set and the chart appears.'
                          : 'One more session with this exercise and the chart appears.',
                ),

              const SectionLabel('Workouts'),
              if (workouts.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Sp.x20, vertical: Sp.x24),
                  child: Center(
                    child: Text(
                      'Your workouts will show up here, newest first.',
                      textAlign: TextAlign.center,
                      style: AppType.meta.copyWith(color: t.muted),
                    ),
                  ),
                )
              else
                _WorkoutList(workouts: workouts),
              const SizedBox(height: Sp.x8),
            ],
          ),
        ),
        Dock(
          child: PrimaryButton(
            _type == WorkoutType.running ? 'Log a run' : 'Start workout',
            onPressed: () => _startSomething(context),
          ),
        ),
      ],
    ).withBackground(t.bg);
  }

  Future<void> _startSomething(BuildContext context) async {
    if (_type == WorkoutType.running) {
      await showRunLogSheet(context);
      return;
    }
    final workout = await showStartWorkoutSheet(context, type: _type);
    if (workout != null && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WorkoutPage(workoutId: workout.id),
        ),
      );
    }
  }

  Future<void> _pickTrackedExercise(BuildContext context) async {
    final app = context.read<AppState>();
    final t = context.t;
    final options =
        app.exercisesOfType(_type).where((e) => e.type == _type).toList();

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Log a workout first — then pick a lift to chart.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: t.sheet,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x10, Sp.x20, Sp.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetGrabber(),
              Text('Chart which exercise?',
                  style: manrope(size: 18, weight: 800, color: t.ink)),
              const SizedBox(height: Sp.x6),
              Text(
                'Everything else still logs and shows in history — it just isn\'t charted.',
                style: AppType.meta.copyWith(color: t.muted),
              ),
              const SizedBox(height: Sp.x14),
              for (final e in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.name,
                      style: AppType.body.copyWith(color: t.ink)),
                  trailing: e.isTracked
                      ? Icon(Icons.check_rounded,
                          size: 18, color: t.pillar(Pillar.training))
                      : null,
                  onTap: () => Navigator.of(context).pop(e),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) await app.setTrackedExercise(picked.id);
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.type,
    required this.tracked,
    required this.series,
    required this.color,
    required this.onPick,
  });

  final WorkoutType type;
  final Exercise? tracked;
  final ChartSeries series;
  final Color color;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final latest = series.latest;
    final label = switch (type) {
      WorkoutType.running => 'Pace · best per run',
      WorkoutType.conditioning => 'Session time',
      _ => tracked?.name ?? 'No lift tracked yet',
    };

    return Row(
      children: [
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(Rad.chip),
          child: Container(
            padding: const EdgeInsets.fromLTRB(Sp.x10, 5, Sp.x8, 5),
            decoration: BoxDecoration(
              color: t.track,
              borderRadius: BorderRadius.circular(Rad.chip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: manrope(
                      size: 13,
                      weight: 700,
                      color: tracked == null && type.chartsByExercise
                          ? t.faint
                          : t.ink,
                    ),
                  ),
                ),
                if (onPick != null) ...[
                  const SizedBox(width: Sp.x6),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: t.muted),
                ],
              ],
            ),
          ),
        ),
        const Spacer(),
        if (latest != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(series.formatValue(latest.value),
                  style: AppType.metricNumber.copyWith(color: t.ink)),
              const SizedBox(width: Sp.x4),
              Text(type.metricUnit,
                  style: manrope(size: 12, weight: 700, color: t.muted)),
            ],
          ),
      ],
    );
  }
}

class _WorkoutList extends StatelessWidget {
  const _WorkoutList({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(Rad.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < workouts.length; i++)
            _WorkoutRow(
              workout: workouts[i],
              isLast: i == workouts.length - 1,
            ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout, required this.isLast});

  final Workout workout;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final parts = <String>[
      if (workout.date != null) DateFormat('d MMM').format(workout.date!),
      if (workout.type.isNested)
        '${workout.exercises.length} ${workout.exercises.length == 1 ? 'exercise' : 'exercises'}'
      else
        _runSummary(workout),
      if (workout.durationMin != null) '${workout.durationMin} min',
    ]..removeWhere((s) => s.isEmpty);

    return Dismissible(
      key: ValueKey(workout.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          context.read<AppState>().deleteWorkout(workout.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Sp.x14),
        color: t.danger,
        child: Text('Delete',
            style: manrope(size: 12, weight: 700, color: t.dangerInk)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WorkoutPage(workoutId: workout.id),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Sp.x14, vertical: Sp.x14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: t.lineSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: manrope(
                              size: 14.5, weight: 600, color: t.ink)),
                      const SizedBox(height: 1),
                      Text(parts.join(' · '),
                          style: manrope(
                              size: 12.5,
                              weight: 500,
                              color: t.muted,
                              tabular: true)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: t.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _runSummary(Workout w) {
    for (final e in w.exercises) {
      for (final s in e.sets) {
        final summary = s.summary();
        if (summary.isNotEmpty) return summary;
      }
    }
    return 'No numbers logged';
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this workout?'),
        content: const Text('Its exercises and sets go with it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: context.t.danger)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _TypeSegments extends StatelessWidget {
  const _TypeSegments({required this.value, required this.onChanged});

  final WorkoutType value;
  final ValueChanged<WorkoutType> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.track,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (final type in WorkoutType.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(type),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: type == value ? t.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      type.label,
                      style: manrope(
                        size: 13,
                        weight: 700,
                        color: type == value ? t.ink : t.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
