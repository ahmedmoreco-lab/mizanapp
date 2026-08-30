import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/set_entry.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

/// Edits one performance. Returns null if cancelled.
Future<SetEntry?> showSetEditor(
  BuildContext context, {
  required SetEntry entry,
  required WorkoutType type,
  required String exerciseName,
  String? lastTime,
}) {
  return showModalBottomSheet<SetEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.t.sheet,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _SetEditor(
        entry: entry,
        type: type,
        exerciseName: exerciseName,
        lastTime: lastTime,
      ),
    ),
  );
}

class _SetEditor extends StatefulWidget {
  const _SetEditor({
    required this.entry,
    required this.type,
    required this.exerciseName,
    this.lastTime,
  });

  final SetEntry entry;
  final WorkoutType type;
  final String exerciseName;
  final String? lastTime;

  @override
  State<_SetEditor> createState() => _SetEditorState();
}

class _SetEditorState extends State<_SetEditor> {
  late final _weight = TextEditingController(text: _fmt(widget.entry.weightKg));
  late final _reps = TextEditingController(text: widget.entry.reps?.toString() ?? '');
  late final _duration =
      TextEditingController(text: _minutes(widget.entry.durationSec));
  late int? _rpe = widget.entry.rpe;

  @override
  void initState() {
    super.initState();
    for (final c in [_weight, _reps, _duration]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _duration.dispose();
    super.dispose();
  }

  bool get _canSave {
    final hasWeight = double.tryParse(_weight.text.trim()) != null;
    final hasReps = int.tryParse(_reps.text.trim()) != null;
    final hasDuration = int.tryParse(_duration.text.trim()) != null;
    return hasWeight || hasReps || hasDuration;
  }

  void _save() {
    final durationMin = int.tryParse(_duration.text.trim());
    Navigator.of(context).pop(
      widget.entry.copyWith(
        weightKg: double.tryParse(_weight.text.trim()),
        clearWeight: double.tryParse(_weight.text.trim()) == null,
        reps: int.tryParse(_reps.text.trim()),
        clearReps: int.tryParse(_reps.text.trim()) == null,
        durationSec: durationMin == null ? null : durationMin * 60,
        clearDuration: durationMin == null,
        rpe: _rpe,
        clearRpe: _rpe == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isStrength = widget.type == WorkoutType.strength;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x10, Sp.x20, Sp.x20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            Text('Set ${widget.entry.setIndex} · ${widget.exerciseName}',
                style: manrope(size: 18, weight: 800, color: t.ink,
                    letterSpacing: -0.27)),
            if (widget.lastTime != null) ...[
              const SizedBox(height: Sp.x4),
              Text('Last time · ${widget.lastTime}',
                  style: manrope(
                      size: 12.5, weight: 600, color: t.faint, tabular: true)),
            ],
            const SizedBox(height: Sp.x14),
            Row(
              children: [
                if (isStrength) ...[
                  Expanded(
                    child: _NumField(
                      label: 'Weight (kg)',
                      controller: _weight,
                      decimal: true,
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: Sp.x8),
                ],
                Expanded(
                  child: _NumField(
                    label: 'Reps',
                    controller: _reps,
                    autofocus: !isStrength,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.x8),
            _NumField(label: 'Duration (min, optional)', controller: _duration),

            const SectionLabel('RPE', top: Sp.x20),
            Wrap(
              spacing: Sp.x6,
              runSpacing: Sp.x6,
              children: [
                for (var i = 1; i <= 10; i++)
                  _RpeChip(
                    value: i,
                    selected: _rpe == i,
                    onTap: () => setState(() => _rpe = _rpe == i ? null : i),
                  ),
              ],
            ),

            const SizedBox(height: Sp.x24),
            PrimaryButton('Save set', onPressed: _canSave ? _save : null),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.label,
    required this.controller,
    this.decimal = false,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;
  final bool autofocus;

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
          autofocus: autofocus,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          style: manrope(size: 15.5, weight: 600, color: t.ink, tabular: true),
          decoration: const InputDecoration(hintText: '—'),
        ),
      ],
    );
  }
}

class _RpeChip extends StatelessWidget {
  const _RpeChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.chip),
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.ink : t.field,
          border: Border.all(color: selected ? t.ink : t.line),
          borderRadius: BorderRadius.circular(Rad.chip),
        ),
        child: Text('$value',
            style: manrope(
                size: 13.5,
                weight: 700,
                color: selected ? t.bg : t.muted,
                tabular: true)),
      ),
    );
  }
}

String _fmt(double? v) {
  if (v == null) return '';
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

String _minutes(int? seconds) =>
    seconds == null ? '' : (seconds ~/ 60).toString();
