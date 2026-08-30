import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/goal.dart';
import '../../models/pillar.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

Future<void> showGoalEditor(BuildContext context, {Goal? goal}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.t.sheet,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _GoalEditor(goal: goal),
    ),
  );
}

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({this.goal});

  final Goal? goal;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.goal?.title ?? '');
  late final TextEditingController _why =
      TextEditingController(text: widget.goal?.whyItMatters ?? '');
  late final TextEditingController _measure =
      TextEditingController(text: widget.goal?.measure ?? '');

  late Pillar _pillar = widget.goal?.pillar ?? Pillar.work;
  late GoalStatus _status = widget.goal?.status ?? GoalStatus.notStarted;
  late DateTime? _target = widget.goal?.targetDate;

  bool get _isNew => widget.goal == null;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _why.dispose();
    _measure.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final title = _title.text.trim();
    if (title.isEmpty) return;

    if (_isNew) {
      final created = await app.addGoal(
        title: title,
        pillar: _pillar,
        whyItMatters: _why.text.trim(),
        measure: _measure.text.trim(),
        targetDate: _target,
      );
      await app.updateGoal(created.copyWith(status: _status));
    } else {
      await app.updateGoal(
        widget.goal!.copyWith(
          title: title,
          pillar: _pillar,
          status: _status,
          whyItMatters: _why.text.trim(),
          measure: _measure.text.trim(),
          targetDate: _target,
          clearTargetDate: _target == null,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canSave = _title.text.trim().isNotEmpty;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x10, Sp.x20, Sp.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetGrabber(),
              Row(
                children: [
                  Expanded(
                    child: Text(_isNew ? 'New goal' : 'Edit goal',
                        style: manrope(
                            size: 18, weight: 800, color: t.ink,
                            letterSpacing: -0.27)),
                  ),
                  if (!_isNew)
                    TextButton(
                      onPressed: _confirmDelete,
                      child: Text('Delete',
                          style: manrope(
                              size: 13, weight: 700, color: t.danger)),
                    ),
                ],
              ),
              const SizedBox(height: Sp.x14),
              TextField(
                controller: _title,
                autofocus: _isNew,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.body.copyWith(color: t.ink, fontSize: 15.5),
                decoration: const InputDecoration(hintText: 'What is the goal?'),
              ),

              const SectionLabel('Pillar', top: Sp.x20),
              Wrap(
                spacing: Sp.x8,
                runSpacing: Sp.x8,
                children: [
                  for (final p in Pillar.values)
                    _PillarChip(
                      pillar: p,
                      selected: p == _pillar,
                      onTap: () => setState(() => _pillar = p),
                    ),
                ],
              ),

              const SectionLabel('Status', top: Sp.x20),
              _StatusSegments(
                value: _status,
                onChanged: (s) => setState(() => _status = s),
              ),

              const SectionLabel('Why it matters', top: Sp.x20),
              Text(
                'You write this, never the app. It is what you read when motivation dips.',
                style: AppType.meta.copyWith(color: t.muted),
              ),
              const SizedBox(height: Sp.x8),
              TextField(
                controller: _why,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.body.copyWith(color: t.ink),
                decoration: const InputDecoration(
                    hintText: 'Because…'),
              ),

              const SectionLabel('Measure', top: Sp.x20),
              TextField(
                controller: _measure,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.body.copyWith(color: t.ink),
                decoration: const InputDecoration(
                    hintText: 'One concrete signal it moved'),
              ),

              const SectionLabel('Target date', top: Sp.x20),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      _target == null
                          ? 'No target date'
                          : DateFormat('d MMMM y').format(_target!),
                      icon: Icons.calendar_today_outlined,
                      onPressed: _pickDate,
                    ),
                  ),
                  if (_target != null) ...[
                    const SizedBox(width: Sp.x8),
                    IconButton(
                      onPressed: () => setState(() => _target = null),
                      icon: Icon(Icons.close_rounded, size: 18, color: t.faint),
                      tooltip: 'Clear target date',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: Sp.x24),
              // Disabled until the goal has a title: there is never a
              // validation error to show.
              PrimaryButton(
                _isNew ? 'Create goal' : 'Save changes',
                onPressed: canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _target ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 6),
    );
    if (picked != null) setState(() => _target = picked);
  }

  Future<void> _confirmDelete() async {
    final goal = widget.goal;
    if (goal == null) return;
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this goal?'),
        content: const Text(
            'Its tasks are kept and simply unlinked — the work was still real.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete',
                style: TextStyle(color: context.t.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteGoal(goal.id);
      navigator.popUntil((r) => r.isFirst);
    }
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip({
    required this.pillar,
    required this.selected,
    required this.onTap,
  });

  final Pillar pillar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = t.pillar(pillar);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.chip),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Sp.x10, vertical: Sp.x8),
        decoration: BoxDecoration(
          color: selected ? c : t.pillarTint(pillar),
          borderRadius: BorderRadius.circular(Rad.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pillarIcon(pillar),
                size: 15, color: selected ? t.onAccent : c),
            const SizedBox(width: Sp.x6),
            Text(pillar.label,
                style: AppType.chip.copyWith(color: selected ? t.onAccent : c)),
          ],
        ),
      ),
    );
  }
}

class _StatusSegments extends StatelessWidget {
  const _StatusSegments({required this.value, required this.onChanged});

  final GoalStatus value;
  final ValueChanged<GoalStatus> onChanged;

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
          for (final s in GoalStatus.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s == value ? t.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    s.label,
                    textAlign: TextAlign.center,
                    style: manrope(
                      size: 11.5,
                      weight: 700,
                      color: s == value ? t.ink : t.muted,
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
