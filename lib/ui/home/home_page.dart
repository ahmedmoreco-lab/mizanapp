import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../logic/focus_engine.dart';
import '../../models/enums.dart';
import '../../models/pillar.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../calendar/calendar_page.dart';
import '../tasks/task_editor_sheet.dart';
import '../widgets/common.dart';

/// Home is an agenda, not a dashboard: what is due today, and what is
/// still floating. The pillar cards that used to live here said very
/// little per pixel; what they were good for survives as one line.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;

    final today = app.todayTasks;
    final done = app.doneToday;
    final loose = app.looseTasks;
    final total = today.length + done.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x6, Sp.x20, Sp.x8),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ScreenTitle(
                      'Today',
                      eyebrow: DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CalendarPage(),
                      ),
                    ),
                    icon: Icon(Icons.calendar_today_outlined,
                        size: 20, color: t.muted),
                    tooltip: 'Calendar',
                  ),
                ],
              ),

              if (total > 0) ...[
                const SizedBox(height: Sp.x10),
                Row(
                  children: [
                    Expanded(
                      child: ThinBar(value: done.length / total, color: t.ink),
                    ),
                    const SizedBox(width: Sp.x14),
                    Text('${done.length} / $total',
                        style: manrope(
                            size: 12.5,
                            weight: 700,
                            color: t.ink,
                            tabular: true)),
                  ],
                ),
              ],

              const _GapsLine(),

              const SectionLabel('Today'),
              if (today.isEmpty && done.isEmpty)
                const EmptyState(
                  title: 'Nothing due today',
                  message:
                      'Give something below a date, or just capture what comes up.',
                  height: 120,
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.x14),
                  child: Column(
                    children: [
                      for (final task in today) TaskLine(task: task),
                      for (final task in done) TaskLine(task: task),
                    ],
                  ),
                ),

              const SectionLabel('Anything else'),
              if (loose.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Sp.x20, vertical: Sp.x20),
                  child: Center(
                    child: Text(
                      'Nothing loose. Type below and it lands here.',
                      textAlign: TextAlign.center,
                      style: AppType.meta.copyWith(color: t.muted),
                    ),
                  ),
                )
              else
                _LooseList(tasks: loose),
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

/// Everything the four pillar cards used to say, in one muted line —
/// and only when there is something to say.
class _GapsLine extends StatefulWidget {
  const _GapsLine();

  @override
  State<_GapsLine> createState() => _GapsLineState();
}

class _GapsLineState extends State<_GapsLine> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final gaps = app.pillarGaps;

    // A pillar touched yesterday is not neglected. Staying quiet is the
    // point: a line that appears every single day stops being read.
    final stale =
        gaps.where((g) => g.never || (g.days ?? 0) >= 2).toList();
    if (stale.isEmpty) return const SizedBox.shrink();

    String label(PillarNeglect g) =>
        g.never ? '${g.pillar.label} never' : '${g.pillar.label} ${g.days}d';

    return Padding(
      padding: const EdgeInsets.only(top: Sp.x14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(Rad.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.x4),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: t.faint),
                  const SizedBox(width: Sp.x6),
                  Expanded(
                    child: Text(
                      'Untouched · ${stale.take(2).map(label).join(' · ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta.copyWith(color: t.muted),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: t.faint,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(top: Sp.x6, left: 19),
              child: Column(
                children: [
                  for (final gap in gaps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          PillarDot(gap.pillar, size: 6),
                          const SizedBox(width: Sp.x8),
                          Expanded(
                            child: Text(gap.pillar.label,
                                style: AppType.meta.copyWith(color: t.muted)),
                          ),
                          Text(
                            gap.never ? 'never' : '${gap.days}d',
                            style: manrope(
                                size: 12,
                                weight: 600,
                                color: t.faint,
                                tabular: true),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LooseList extends StatefulWidget {
  const _LooseList({required this.tasks});

  final List<Task> tasks;

  @override
  State<_LooseList> createState() => _LooseListState();
}

class _LooseListState extends State<_LooseList> {
  static const _collapsed = 6;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final shown =
        _all ? widget.tasks : widget.tasks.take(_collapsed).toList();
    final hidden = widget.tasks.length - shown.length;

    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Sp.x14),
          child: Column(
            children: [for (final task in shown) TaskLine(task: task)],
          ),
        ),
        if (hidden > 0 || _all)
          Padding(
            padding: const EdgeInsets.only(top: Sp.x8),
            child: GhostButton(
              _all ? 'Show fewer' : 'Show all ${widget.tasks.length}',
              bordered: false,
              onPressed: () => setState(() => _all = !_all),
            ),
          ),
      ],
    );
  }
}

/// One task, anywhere. A filled dot carries the pillar colour; an unfiled
/// task gets a hollow ring, because no colour is what "not filed" looks
/// like in a system where colour means pillar.
class TaskLine extends StatelessWidget {
  const TaskLine({super.key, required this.task, this.showDate = false});

  final Task task;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pillar = task.pillar;
    final color = pillar == null ? t.faint : t.pillar(pillar);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<AppState>().deleteTask(task.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Sp.x8),
        color: t.danger,
        child: Text('Delete',
            style: manrope(size: 12, weight: 700, color: t.dangerInk)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            TaskCheck(
              done: task.done,
              color: pillar == null ? t.ink : color,
              onTap: () => context.read<AppState>().toggleTask(task.id),
            ),
            const SizedBox(width: Sp.x10),
            if (pillar == null)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.faint, width: 1.4),
                ),
              )
            else
              PillarDot(pillar),
            const SizedBox(width: Sp.x10),
            Expanded(
              child: GestureDetector(
                onTap: () => showTaskEditor(context, task),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(
                    color: task.done ? t.faint : t.ink,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    decorationColor: t.faint,
                  ),
                ),
              ),
            ),
            if (!task.done && task.priority == Priority.high)
              const Padding(
                padding: EdgeInsets.only(left: Sp.x8),
                child: TintPill('High'),
              ),
            if (!task.done && task.isOverdue)
              Padding(
                padding: const EdgeInsets.only(left: Sp.x8),
                child: TintPill('Overdue', color: t.danger),
              ),
            if (showDate && !task.isOverdue && task.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(left: Sp.x8),
                child: Text(
                  DateFormat('d MMM').format(task.dueDate!),
                  style: manrope(
                      size: 11.5, weight: 600, color: t.faint, tabular: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
