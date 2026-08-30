import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/pillar.dart';
import '../../models/set_entry.dart';
import '../../models/workout.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'set_editor_sheet.dart';
import 'start_workout_sheet.dart' show promptForText;

/// Workout → exercises → sets, all editable from this one screen.
class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final workout = app.workoutById(workoutId);

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('This workout was deleted.',
              style: AppType.body.copyWith(color: t.muted)),
        ),
      );
    }

    final color = t.pillar(Pillar.training);
    final subtitle = <String>[
      if (workout.date != null) DateFormat('d MMM').format(workout.date!),
      if (workout.templateId != null) 'from template',
      if (workout.durationMin != null) '${workout.durationMin} min',
    ];

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.x8, Sp.x4, Sp.x8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.chevron_left_rounded, color: t.muted),
                    tooltip: 'Back to training',
                  ),
                  Text('Training',
                      style: manrope(size: 14, weight: 600, color: t.muted)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        size: 18, color: t.muted),
                    tooltip: 'Workout options',
                    onSelected: (v) => _onMenu(context, workout, v),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'duration', child: Text('Set duration')),
                      PopupMenuItem(
                          value: 'template', child: Text('Save as template')),
                      PopupMenuItem(
                          value: 'delete', child: Text('Delete workout')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(Sp.x20, Sp.x4, Sp.x20, Sp.x8),
                children: [
                  Text(workout.title,
                      style: AppType.subScreenTitle.copyWith(color: t.ink)),
                  const SizedBox(height: Sp.x6),
                  Text(subtitle.join(' · '),
                      style: manrope(
                          size: 12.5,
                          weight: 500,
                          color: t.muted,
                          tabular: true)),

                  const SectionLabel('Exercises'),
                  if (workout.exercises.isEmpty)
                    const EmptyState(
                      title: 'No exercises yet',
                      message:
                          'Add the first one below. You can build the whole workout and fill numbers in as you go.',
                      height: 130,
                    )
                  else
                    for (final we in workout.exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Sp.x10),
                        child: _ExerciseCard(
                          workout: workout,
                          exercise: we,
                          accent: color,
                        ),
                      ),
                  const SizedBox(height: Sp.x4),
                  GhostButton(
                    'Add exercise',
                    icon: Icons.add_rounded,
                    onPressed: () => _addExercise(context, workout),
                  ),

                  const SectionLabel('Notes'),
                  _NotesField(workout: workout),
                  const SizedBox(height: Sp.x8),
                ],
              ),
            ),
            Dock(
              child: PrimaryButton(
                'Finish workout',
                // Error prevention: there is nothing to finish until at
                // least one set exists, so the button simply isn't ready.
                onPressed:
                    workout.hasAnySet ? () => Navigator.of(context).pop() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, Workout workout) async {
    final app = context.read<AppState>();
    final picked = await showExercisePicker(context, type: workout.type);
    if (picked == null) return;
    await app.addExerciseToWorkout(workout.id, picked);
  }

  Future<void> _onMenu(
      BuildContext context, Workout workout, String value) async {
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    switch (value) {
      case 'rename':
        final name = await promptForText(context,
            title: 'Rename workout', initial: workout.title);
        if (name != null && name.trim().isNotEmpty) {
          await app.saveWorkout(workout.copyWith(title: name.trim()));
        }
        break;
      case 'duration':
        final mins = await promptForText(context,
            title: 'Duration in minutes',
            initial: workout.durationMin?.toString() ?? '',
            hint: 'e.g. 48');
        final parsed = int.tryParse((mins ?? '').trim());
        await app.saveWorkout(workout.copyWith(
          durationMin: parsed,
          clearDuration: parsed == null,
        ));
        break;
      case 'template':
        final name = await promptForText(context,
            title: 'Save as template', initial: workout.title);
        if (name != null && name.trim().isNotEmpty) {
          await app.saveAsTemplate(workout.id, title: name);
          messenger.showSnackBar(
            SnackBar(content: Text('Saved "${name.trim()}" as a template')),
          );
        }
        break;
      case 'delete':
        await app.deleteWorkout(workout.id);
        navigator.pop();
        break;
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.workout,
    required this.exercise,
    required this.accent,
  });

  final Workout workout;
  final WorkoutExercise exercise;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final name = app.exerciseName(exercise.exerciseId);
    final lastTime = app.lastPerformance(exercise.exerciseId,
        excludingWorkoutId: workout.id);

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(Rad.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(Sp.x14, Sp.x10, Sp.x4, Sp.x10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.lineSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: manrope(size: 15, weight: 700, color: t.ink)),
                      const SizedBox(height: 1),
                      // Last week's numbers sit where you decide today's
                      // load, not in a chart you check afterwards.
                      Text(
                        exercise.sets.isEmpty && lastTime == null
                            ? 'No sets yet'
                            : lastTime == null
                                ? '${exercise.sets.length} ${exercise.sets.length == 1 ? 'set' : 'sets'}'
                                : 'Last time · $lastTime',
                        style: manrope(
                            size: 12, weight: 600, color: t.faint,
                            tabular: true),
                      ),
                      // The target from the template — sets, reps, load,
                      // cue — stays in front of you while you log.
                      if (exercise.notes.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3, right: Sp.x8),
                          child: Text(
                            exercise.notes,
                            style: manrope(
                                size: 12, weight: 500, color: t.muted,
                                height: 1.35),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: t.faint),
                  tooltip: 'Exercise options',
                  onSelected: (v) async {
                    final state = context.read<AppState>();
                    if (v == 'remove') {
                      await state.removeExerciseFromWorkout(
                          workout.id, exercise.id);
                    } else if (v == 'chart') {
                      await state.setTrackedExercise(exercise.exerciseId);
                    }
                  },
                  itemBuilder: (context) => [
                    if (workout.type != WorkoutType.running)
                      const PopupMenuItem(
                          value: 'chart', child: Text('Chart this exercise')),
                    const PopupMenuItem(
                        value: 'remove', child: Text('Remove from workout')),
                  ],
                ),
              ],
            ),
          ),
          for (final set in exercise.sets)
            _SetRow(
              workout: workout,
              exercise: exercise,
              entry: set,
              name: name,
              lastTime: lastTime,
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _addSet(context, name, lastTime),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Sp.x14, vertical: 11),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: t.muted),
                    const SizedBox(width: Sp.x8),
                    Text('Add set',
                        style:
                            manrope(size: 13.5, weight: 700, color: t.muted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSet(
      BuildContext context, String name, String? lastTime) async {
    final app = context.read<AppState>();
    final draft = SetEntry(
      id: app.newId(),
      setIndex: exercise.sets.length + 1,
    );
    final result = await showSetEditor(
      context,
      entry: draft,
      type: workout.type,
      exerciseName: name,
      lastTime: lastTime,
    );
    if (result != null) {
      await app.upsertSet(workout.id, exercise.id, result);
    }
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.workout,
    required this.exercise,
    required this.entry,
    required this.name,
    required this.lastTime,
  });

  final Workout workout;
  final WorkoutExercise exercise;
  final SetEntry entry;
  final String name;
  final String? lastTime;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    // Swipe to reveal delete — the same gesture at set, exercise and
    // workout level, so removing something is never a hunt.
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context
          .read<AppState>()
          .deleteSet(workout.id, exercise.id, entry.id),
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
          onTap: () => _edit(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Sp.x14, vertical: Sp.x10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.lineSoft)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text('${entry.setIndex}',
                      style: manrope(
                          size: 12, weight: 700, color: t.faint, tabular: true)),
                ),
                const SizedBox(width: Sp.x10),
                Expanded(
                  child: Text(
                    entry.summary().isEmpty ? 'Tap to fill in' : entry.summary(),
                    style: AppType.setValue.copyWith(
                        color: entry.isEmpty ? t.faint : t.ink),
                  ),
                ),
                if (entry.rpe != null) TintPill('RPE ${entry.rpe}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final app = context.read<AppState>();
    final result = await showSetEditor(
      context,
      entry: entry,
      type: workout.type,
      exerciseName: name,
      lastTime: lastTime,
    );
    if (result != null) {
      await app.upsertSet(workout.id, exercise.id, result);
    }
  }
}

class _NotesField extends StatefulWidget {
  const _NotesField({required this.workout});

  final Workout workout;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final _controller = TextEditingController(text: widget.workout.notes);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return TextField(
      controller: _controller,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      style: AppType.body.copyWith(color: t.ink),
      decoration: const InputDecoration(
          hintText: 'Anything the fields don\'t catch…'),
      onChanged: (v) => context
          .read<AppState>()
          .saveWorkout(widget.workout.copyWith(notes: v)),
    );
  }
}

/// Exercise picker: chips of what you've logged before, plus a new one.
/// You never retype "Back squat".
Future<String?> showExercisePicker(
  BuildContext context, {
  required WorkoutType type,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.t.sheet,
    builder: (_) => _ExercisePicker(type: type),
  );
}

class _ExercisePicker extends StatelessWidget {
  const _ExercisePicker({required this.type});

  final WorkoutType type;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final known =
        app.exercisesOfType(type).where((e) => e.type == type).toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x10, Sp.x20, Sp.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetGrabber(),
              Text('Add an exercise',
                  style: manrope(
                      size: 18, weight: 800, color: t.ink, letterSpacing: -0.27)),
              const SizedBox(height: Sp.x14),
              if (known.isNotEmpty)
                Wrap(
                  spacing: Sp.x6,
                  runSpacing: Sp.x6,
                  children: [
                    for (final e in known)
                      InkWell(
                        onTap: () => Navigator.of(context).pop(e.id),
                        borderRadius: BorderRadius.circular(Rad.chip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: Sp.x6),
                          decoration: BoxDecoration(
                            color: t.field,
                            border: Border.all(color: t.line),
                            borderRadius: BorderRadius.circular(Rad.chip),
                          ),
                          child: Text(e.name,
                              style: AppType.chip.copyWith(color: t.ink)),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: Sp.x14),
              GhostButton(
                'New exercise',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final state = context.read<AppState>();
                  final navigator = Navigator.of(context);
                  final name = await promptForText(
                    context,
                    title: 'New exercise',
                    hint: 'e.g. Bulgarian split squat',
                  );
                  if (name == null || name.trim().isEmpty) return;
                  final created = await state.ensureExercise(name, type);
                  navigator.pop(created.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
