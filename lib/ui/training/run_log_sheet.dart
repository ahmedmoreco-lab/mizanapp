import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/set_entry.dart';
import '../../models/workout.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

/// A run is one activity, not a list. Same tables underneath — one set
/// attached to one "Run" exercise — but the screen doesn't make you build
/// a list for a single activity.
Future<void> showRunLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.t.sheet,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: const _RunLogSheet(),
    ),
  );
}

const _runKinds = ['Easy', 'Zone 2', 'Intervals', 'Long'];

class _RunLogSheet extends StatefulWidget {
  const _RunLogSheet();

  @override
  State<_RunLogSheet> createState() => _RunLogSheetState();
}

class _RunLogSheetState extends State<_RunLogSheet> {
  final _distance = TextEditingController();
  final _duration = TextEditingController();
  final _notes = TextEditingController();
  String _kind = 'Zone 2';
  int? _rpe;

  @override
  void initState() {
    super.initState();
    _distance.addListener(() => setState(() {}));
    _duration.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _distance.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? get _km => double.tryParse(_distance.text.trim());
  int? get _seconds => parseDuration(_duration.text);

  double? get _pace {
    final km = _km;
    final secs = _seconds;
    if (km == null || secs == null || km <= 0) return null;
    return secs / km;
  }

  bool get _canSave => _km != null || _seconds != null;

  Future<void> _save() async {
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);

    final exercise = await app.ensureExercise('Run', WorkoutType.running);
    final workout = await app.startBlankWorkout(WorkoutType.running);
    final secs = _seconds;

    await app.saveWorkout(
      workout.copyWith(
        title: '$_kind run',
        durationMin: secs == null ? null : (secs / 60).round(),
        notes: _notes.text.trim(),
        exercises: [
          WorkoutExerciseBuilder.single(
            id: app.newId(),
            exerciseId: exercise.id,
            setId: app.newId(),
            distanceKm: _km,
            durationSec: secs,
            rpe: _rpe,
          ),
        ],
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pace = _pace;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x10, Sp.x20, Sp.x20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            Text('Log a run',
                style: manrope(
                    size: 18, weight: 800, color: t.ink, letterSpacing: -0.27)),

            const SectionLabel('Type', top: Sp.x14),
            Wrap(
              spacing: Sp.x6,
              runSpacing: Sp.x6,
              children: [
                for (final kind in _runKinds)
                  InkWell(
                    onTap: () => setState(() => _kind = kind),
                    borderRadius: BorderRadius.circular(Rad.chip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: Sp.x6),
                      decoration: BoxDecoration(
                        color: _kind == kind ? t.ink : t.field,
                        border: Border.all(
                            color: _kind == kind ? t.ink : t.line),
                        borderRadius: BorderRadius.circular(Rad.chip),
                      ),
                      child: Text(kind,
                          style: AppType.chip.copyWith(
                              color: _kind == kind ? t.bg : t.muted)),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: Sp.x20),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'Distance (km)',
                    controller: _distance,
                    hint: '8.20',
                    decimal: true,
                  ),
                ),
                const SizedBox(width: Sp.x8),
                Expanded(
                  child: _Field(
                    label: 'Duration',
                    controller: _duration,
                    hint: '44:10',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.x8),
            Row(
              children: [
                // Pace is computed. Never ask for something you can work out.
                Expanded(
                  child: _ReadOnlyField(
                    label: 'Pace · auto',
                    value: pace == null ? '—' : '${formatPace(pace)} /km',
                  ),
                ),
                const SizedBox(width: Sp.x8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RPE',
                          style: AppType.sectionLabel.copyWith(color: t.faint)),
                      const SizedBox(height: Sp.x6),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (var i = 1; i <= 10; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: Sp.x6),
                                child: InkWell(
                                  onTap: () => setState(
                                      () => _rpe = _rpe == i ? null : i),
                                  borderRadius:
                                      BorderRadius.circular(Rad.chip),
                                  child: Container(
                                    width: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _rpe == i ? t.ink : t.field,
                                      border: Border.all(
                                          color: _rpe == i ? t.ink : t.line),
                                      borderRadius:
                                          BorderRadius.circular(Rad.chip),
                                    ),
                                    child: Text('$i',
                                        style: manrope(
                                            size: 13,
                                            weight: 700,
                                            color:
                                                _rpe == i ? t.bg : t.muted,
                                            tabular: true)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SectionLabel('Notes', top: Sp.x20),
            TextField(
              controller: _notes,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: AppType.body.copyWith(color: t.ink),
              decoration: const InputDecoration(
                  hintText: 'Legs heavy from yesterday\'s squats…'),
            ),

            const SizedBox(height: Sp.x24),
            PrimaryButton('Save run', onPressed: _canSave ? _save : null),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.decimal = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppType.sectionLabel.copyWith(color: t.faint)),
        const SizedBox(height: Sp.x6),
        TextField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: manrope(size: 15.5, weight: 600, color: t.ink, tabular: true),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppType.sectionLabel.copyWith(color: t.faint)),
        const SizedBox(height: Sp.x6),
        Container(
          height: 46,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: Sp.x14),
          decoration: BoxDecoration(
            color: t.track,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(value,
              style:
                  manrope(size: 15.5, weight: 600, color: t.ink, tabular: true)),
        ),
      ],
    );
  }
}

/// Accepts "44:10", "1:04:20" or plain minutes.
int? parseDuration(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  if (!text.contains(':')) {
    final minutes = double.tryParse(text);
    return minutes == null ? null : (minutes * 60).round();
  }
  final parts = text.split(':').map((p) => int.tryParse(p.trim())).toList();
  if (parts.any((p) => p == null)) return null;
  if (parts.length == 2) return parts[0]! * 60 + parts[1]!;
  if (parts.length == 3) return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
  return null;
}

/// Small helper so the run sheet can build its single-exercise workout
/// without reaching into the workout internals.
abstract final class WorkoutExerciseBuilder {
  static WorkoutExercise single({
    required String id,
    required String exerciseId,
    required String setId,
    double? distanceKm,
    int? durationSec,
    int? rpe,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      orderIndex: 0,
      sets: [
        SetEntry(
          id: setId,
          setIndex: 1,
          distanceKm: distanceKm,
          durationSec: durationSec,
          rpe: rpe,
        ),
      ],
    );
  }
}
