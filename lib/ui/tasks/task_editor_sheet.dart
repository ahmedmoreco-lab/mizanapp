import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/pillar.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

/// Capture first, file later. Quick-add takes a title and nothing else;
/// this is where a captured task gets its pillar, goal, date and priority
/// whenever you get round to it.
Future<void> showTaskEditor(BuildContext context, Task task) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.t.sheet,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _TaskEditor(task: task),
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.task});

  final Task task;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final _title = TextEditingController(text: widget.task.title);
  late final _notes = TextEditingController(text: widget.task.notes);
  late Pillar? _pillar = widget.task.pillar;
  late String? _goalId = widget.task.goalId;
  late Priority? _priority = widget.task.priority;
  late DateTime? _due = widget.task.dueDate;
  late bool _pinned = widget.task.isTodayFocus;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    await app.updateTask(
      widget.task.copyWith(
        title: _title.text.trim(),
        pillar: _pillar,
        clearPillar: _pillar == null,
        goalId: _goalId,
        clearGoal: _goalId == null,
        priority: _priority,
        clearPriority: _priority == null,
        dueDate: _due,
        clearDueDate: _due == null,
        notes: _notes.text.trim(),
        isTodayFocus: _pinned,
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final goal = _goalId == null ? null : app.goalById(_goalId!);

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
                    child: Text('Task',
                        style: manrope(
                            size: 18,
                            weight: 800,
                            color: t.ink,
                            letterSpacing: -0.27)),
                  ),
                  TextButton(
                    onPressed: _confirmDelete,
                    child: Text('Delete',
                        style:
                            manrope(size: 13, weight: 700, color: t.danger)),
                  ),
                ],
              ),
              const SizedBox(height: Sp.x10),
              TextField(
                controller: _title,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.body.copyWith(color: t.ink, fontSize: 15.5),
                decoration: const InputDecoration(hintText: 'What is it?'),
              ),

              const SectionLabel('Pillar', top: Sp.x20),
              Wrap(
                spacing: Sp.x6,
                runSpacing: Sp.x6,
                children: [
                  _Choice(
                    label: 'Unfiled',
                    selected: _pillar == null,
                    onTap: () => setState(() => _pillar = null),
                  ),
                  for (final p in Pillar.values)
                    _Choice(
                      label: p.label,
                      icon: pillarIcon(p),
                      accent: t.pillar(p),
                      selected: _pillar == p,
                      onTap: () => setState(() => _pillar = p),
                    ),
                ],
              ),

              const SectionLabel('Goal', top: Sp.x20),
              AppCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: Sp.x14, vertical: Sp.x10),
                onTap: () => _pickGoal(app),
                child: Row(
                  children: [
                    if (goal != null) ...[
                      PillarDot(goal.pillar),
                      const SizedBox(width: Sp.x10),
                    ],
                    Expanded(
                      child: Text(
                        goal?.title ?? 'Not linked to a goal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(
                            color: goal == null ? t.faint : t.ink),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: t.faint),
                  ],
                ),
              ),

              const SectionLabel('Priority', top: Sp.x20),
              Wrap(
                spacing: Sp.x6,
                runSpacing: Sp.x6,
                children: [
                  _Choice(
                    label: 'None',
                    selected: _priority == null,
                    onTap: () => setState(() => _priority = null),
                  ),
                  for (final p in Priority.values)
                    _Choice(
                      label: p.label,
                      selected: _priority == p,
                      onTap: () => setState(() => _priority = p),
                    ),
                ],
              ),

              const SectionLabel('Due', top: Sp.x20),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      _due == null
                          ? 'No due date'
                          : DateFormat('d MMMM y').format(_due!),
                      icon: Icons.calendar_today_outlined,
                      onPressed: _pickDate,
                    ),
                  ),
                  if (_due != null) ...[
                    const SizedBox(width: Sp.x8),
                    IconButton(
                      onPressed: () => setState(() => _due = null),
                      icon: Icon(Icons.close_rounded, size: 18, color: t.faint),
                      tooltip: 'Clear due date',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: Sp.x14),
              AppCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: Sp.x14, vertical: Sp.x4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Pin to today',
                          style: AppType.body.copyWith(color: t.ink)),
                    ),
                    Switch(
                      value: _pinned,
                      onChanged: (v) => setState(() => _pinned = v),
                    ),
                  ],
                ),
              ),

              const SectionLabel('Notes', top: Sp.x20),
              TextField(
                controller: _notes,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.body.copyWith(color: t.ink),
                decoration: const InputDecoration(
                    hintText: 'Anything the fields don\'t catch…'),
              ),

              const SizedBox(height: Sp.x24),
              PrimaryButton(
                'Save',
                onPressed: _title.text.trim().isEmpty ? null : _save,
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
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 6),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _pickGoal(AppState app) async {
    final t = context.t;
    final chosen = await showModalBottomSheet<String>(
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
              Text('Link to a goal',
                  style: manrope(size: 18, weight: 800, color: t.ink)),
              const SizedBox(height: Sp.x10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Not linked',
                    style: AppType.body.copyWith(color: t.muted)),
                onTap: () => Navigator.of(context).pop(''),
              ),
              for (final g in app.goals)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: PillarDot(g.pillar),
                  title: Text(g.title,
                      style: AppType.body.copyWith(color: t.ink)),
                  onTap: () => Navigator.of(context).pop(g.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    setState(() {
      _goalId = chosen.isEmpty ? null : chosen;
      // Linking to a goal adopts its pillar unless one is already set.
      final g = _goalId == null ? null : app.goalById(_goalId!);
      if (g != null && _pillar == null) _pillar = g.pillar;
    });
  }

  Future<void> _confirmDelete() async {
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: const Text('There is no undo.'),
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
    if (ok == true) {
      await app.deleteTask(widget.task.id);
      navigator.pop();
    }
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = accent ?? t.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.chip),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Sp.x10, vertical: Sp.x8),
        decoration: BoxDecoration(
          color: selected
              ? c
              : (accent == null ? t.field : c.withValues(alpha: t.tint)),
          border: Border.all(
              color: selected ? c : (accent == null ? t.line : Colors.transparent)),
          borderRadius: BorderRadius.circular(Rad.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: selected ? t.onAccent : (accent ?? t.muted)),
              const SizedBox(width: Sp.x6),
            ],
            Text(
              label,
              style: AppType.chip.copyWith(
                color: selected
                    ? t.onAccent
                    : (accent ?? t.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
