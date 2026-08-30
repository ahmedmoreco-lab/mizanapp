import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/pillar.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../tasks/task_editor_sheet.dart';
import '../widgets/common.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return app.isFocusConfirmedToday
        ? const _TodayView()
        : const _SuggestView();
  }
}

String _todayLabel() => DateFormat('EEEE, d MMMM').format(DateTime.now());

// ---------------------------------------------------------------- suggest

class _SuggestView extends StatefulWidget {
  const _SuggestView();

  @override
  State<_SuggestView> createState() => _SuggestViewState();
}

class _SuggestViewState extends State<_SuggestView> {
  /// Pillars the user has dropped from today's set. Held locally so
  /// nothing is written until Confirm — the suggestion is never auto-locked.
  final Set<Pillar> _dropped = {};
  final List<Pillar> _added = [];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;

    final suggestions = app.suggestions
        .where((s) => !_dropped.contains(s.pillar))
        .toList();
    final chosen = <Pillar>[
      ...suggestions.map((s) => s.pillar),
      ..._added,
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x6, Sp.x20, Sp.x8),
            children: [
              ScreenTitle(
                'Today',
                eyebrow: _todayLabel(),
                subtitle: suggestions.isEmpty && _added.isEmpty
                    ? 'Nothing is asking for attention yet. Add a pillar, or just capture something.'
                    : 'These pillars look like they want your attention. Drop any that don\'t fit.',
              ),
              const SectionLabel('Suggested focus'),
              for (final s in suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.x10),
                  child: _SuggestCard(
                    pillar: s.pillar,
                    reason: s.reason,
                    onRemove: () => setState(() => _dropped.add(s.pillar)),
                  ),
                ),
              for (final p in _added)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.x10),
                  child: _SuggestCard(
                    pillar: p,
                    reason: 'Added by you',
                    onRemove: () => setState(() => _added.remove(p)),
                  ),
                ),
              GhostButton(
                'Add a pillar',
                icon: Icons.add_rounded,
                onPressed: () => _pickPillar(context, chosen),
              ),
              const SizedBox(height: Sp.x8),
            ],
          ),
        ),
        Dock(
          child: PrimaryButton(
            chosen.isEmpty ? 'Start with nothing set' : 'Confirm today\'s focus',
            onPressed: () => context.read<AppState>().confirmFocus(chosen),
          ),
        ),
      ],
    ).withBackground(t.bg);
  }

  Future<void> _pickPillar(BuildContext context, List<Pillar> already) async {
    final picked = await showPillarPicker(context, exclude: already.toSet());
    if (picked != null && mounted) {
      setState(() {
        _dropped.remove(picked);
        if (!_added.contains(picked)) _added.add(picked);
      });
    }
  }
}

class _SuggestCard extends StatelessWidget {
  const _SuggestCard({
    required this.pillar,
    required this.reason,
    required this.onRemove,
  });

  final Pillar pillar;
  final String reason;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      child: Row(
        children: [
          PillarBadge(pillar),
          const SizedBox(width: Sp.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pillar.label,
                    style: manrope(size: 15.5, weight: 700, color: t.ink)),
                const SizedBox(height: 1),
                Text(reason, style: AppType.meta.copyWith(color: t.muted)),
              ],
            ),
          ),
          // Deliberately a smaller target than Confirm: dropping a pillar
          // should be possible, not accidental.
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 16, color: t.faint),
            splashRadius: 18,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            tooltip: 'Drop ${pillar.label}',
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ today

class _TodayView extends StatelessWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final pillars = app.focusPillars;

    var done = 0;
    var total = 0;
    for (final p in pillars) {
      done += app.tasksDoneTodayFor(p).length;
      total += app.tasksDoneTodayFor(p).length + app.openTasksFor(p).length;
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x6, Sp.x20, Sp.x8),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ScreenTitle('Today', eyebrow: _todayLabel())),
                  TextButton(
                    onPressed: () => context.read<AppState>().reopenFocus(),
                    child: Text('Adjust',
                        style: manrope(size: 13, weight: 700, color: t.muted)),
                  ),
                ],
              ),
              const SizedBox(height: Sp.x14),
              Row(
                children: [
                  Expanded(
                    child: ThinBar(
                      value: total == 0 ? 0 : done / total,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(width: Sp.x14),
                  Text('$done / $total',
                      style: manrope(
                          size: 12.5, weight: 700, color: t.ink, tabular: true)),
                ],
              ),
              if (pillars.isEmpty) ...[
                const SectionLabel('Focus'),
                const EmptyState(
                  title: 'No pillars set for today',
                  message:
                      'Tap Adjust to pick a few, or just capture things below and file them later.',
                ),
              ] else ...[
                const SectionLabel('Focus'),
                for (final p in pillars)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.x10),
                    child: _FocusCard(pillar: p),
                  ),
              ],
              if (app.inbox.isNotEmpty) ...[
                const SectionLabel('Inbox'),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.x14),
                  child: Column(
                    children: [
                      for (final task in app.inbox.take(5))
                        _TaskRow(task: task, color: t.muted),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Sp.x8),
            ],
          ),
        ),
        Dock(
          child: QuickAddField(
            hint: 'Capture anything…',
            onSubmit: (text) => context.read<AppState>().addTask(title: text),
          ),
        ),
      ],
    ).withBackground(t.bg);
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.pillar});

  final Pillar pillar;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final color = t.pillar(pillar);

    final open = app.openTasksFor(pillar);
    final doneToday = app.tasksDoneTodayFor(pillar);
    final total = open.length + doneToday.length;

    // Progressive disclosure: two tasks, then a count. Home is not a backlog.
    final shown = <Task>[...doneToday.take(1), ...open.take(2)];
    final hidden = total - shown.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillarBadge(pillar),
              const SizedBox(width: Sp.x10),
              Expanded(
                child: Text(pillar.label,
                    style: manrope(size: 15.5, weight: 700, color: t.ink)),
              ),
              Text('${doneToday.length}/$total',
                  style: manrope(
                      size: 12.5, weight: 700, color: t.muted, tabular: true)),
            ],
          ),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.only(top: Sp.x8),
              child: Text('No task yet — capture one below',
                  style: AppType.meta.copyWith(color: t.muted)),
            )
          else ...[
            const SizedBox(height: Sp.x10),
            ThinBar(value: doneToday.length / total, color: color),
            const SizedBox(height: Sp.x4),
            for (final task in shown) _TaskRow(task: task, color: color),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(left: 29, top: Sp.x4),
                child: Text('+$hidden more',
                    style: AppType.meta.copyWith(color: t.muted)),
              ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.color});

  final Task task;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          TaskCheck(
            done: task.done,
            color: color,
            onTap: () => context.read<AppState>().toggleTask(task.id),
          ),
          const SizedBox(width: Sp.x10),
          Expanded(
            child: GestureDetector(
              onTap: () => showTaskEditor(context, task),
              behavior: HitTestBehavior.opaque,
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body.copyWith(
                  color: task.done ? t.faint : t.ink,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                  decorationColor: t.faint,
                ),
              ),
            ),
          ),
          // Only High is shown. Medium and Low still sort, but a label on
          // every row would be noise on the screen meant to stay sparse.
          if (task.priority == Priority.high && !task.done)
            const Padding(
              padding: EdgeInsets.only(left: Sp.x8),
              child: TintPill('High'),
            ),
          if (task.isOverdue && !task.done)
            Padding(
              padding: const EdgeInsets.only(left: Sp.x8),
              child: TintPill('Overdue', color: t.danger),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- pillar picker

Future<Pillar?> showPillarPicker(
  BuildContext context, {
  Set<Pillar> exclude = const {},
  String title = 'Pick a pillar',
}) {
  final t = context.t;
  final options =
      Pillar.values.where((p) => !exclude.contains(p)).toList();
  return showModalBottomSheet<Pillar>(
    context: context,
    backgroundColor: t.sheet,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x10, Sp.x20, Sp.x20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetGrabber(),
            Text(title,
                style: AppType.subScreenTitle.copyWith(color: t.ink, fontSize: 18)),
            const SizedBox(height: Sp.x14),
            if (options.isEmpty)
              Text('Every pillar is already in today\'s set.',
                  style: AppType.body.copyWith(color: t.muted))
            else
              Wrap(
                spacing: Sp.x8,
                runSpacing: Sp.x8,
                children: [
                  for (final p in options)
                    InkWell(
                      onTap: () => Navigator.of(context).pop(p),
                      borderRadius: BorderRadius.circular(Rad.chip),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Sp.x10, vertical: Sp.x8),
                        decoration: BoxDecoration(
                          color: t.pillarTint(p),
                          borderRadius: BorderRadius.circular(Rad.chip),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(pillarIcon(p),
                                size: 15, color: t.pillar(p)),
                            const SizedBox(width: Sp.x6),
                            Text(p.label,
                                style: AppType.chip.copyWith(color: t.pillar(p))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
