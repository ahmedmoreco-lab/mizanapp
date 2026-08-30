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
import 'goal_edit_sheet.dart';

class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final goal = app.goalById(goalId);

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('This goal was deleted.',
              style: AppType.body.copyWith(color: t.muted)),
        ),
      );
    }

    final color = t.pillar(goal.pillar);
    final progress = app.progressForGoal(goal.id);
    final tasks = app.tasksForGoal(goal.id);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.x8, Sp.x4, Sp.x14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.chevron_left_rounded, color: t.muted),
                    tooltip: 'Back to goals',
                  ),
                  Text('Goals',
                      style: manrope(size: 14, weight: 600, color: t.muted)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Sp.x8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.pillarTint(goal.pillar),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PillarDot(goal.pillar, size: 6),
                        const SizedBox(width: Sp.x6),
                        Text(goal.pillar.label,
                            style: manrope(size: 11, weight: 700, color: color)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showGoalEditor(context, goal: goal),
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: t.muted),
                    tooltip: 'Edit goal',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(Sp.x20, Sp.x4, Sp.x20, Sp.x8),
                children: [
                  Text(goal.title,
                      style: AppType.subScreenTitle.copyWith(color: t.ink)),
                  const SizedBox(height: Sp.x14),
                  Row(
                    children: [
                      Expanded(
                        child: ThinBar(
                            value: progress.fraction, height: 5, color: color),
                      ),
                      const SizedBox(width: Sp.x14),
                      Text('${progress.done}/${progress.total}',
                          style: manrope(
                              size: 12.5,
                              weight: 700,
                              color: t.ink,
                              tabular: true)),
                    ],
                  ),
                  if (goal.targetDate != null || goal.status != GoalStatus.inProgress)
                    Padding(
                      padding: const EdgeInsets.only(top: Sp.x8),
                      child: Row(
                        children: [
                          TintPill(goal.status.label,
                              color: goal.status.isLive ? color : null),
                          if (goal.targetDate != null) ...[
                            const SizedBox(width: Sp.x8),
                            Text(
                              'Target · ${DateFormat('d MMM y').format(goal.targetDate!)}',
                              style: AppType.meta.copyWith(color: t.muted),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Why and Measure sit above the task list, because the
                  // moment you open a stalled goal is the moment you need them.
                  const SectionLabel('Why it matters'),
                  if (goal.whyItMatters.trim().isEmpty)
                    _WriteItYourself(
                      hint:
                          'Nothing written yet. This is the line you read when motivation dips — worth two minutes.',
                      onTap: () => showGoalEditor(context, goal: goal),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.only(left: 13),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: color, width: 2),
                        ),
                      ),
                      child: Text(
                        goal.whyItMatters,
                        style: AppType.body.copyWith(
                            color: t.ink, fontSize: 15, height: 1.5),
                      ),
                    ),

                  const SectionLabel('Measure'),
                  if (goal.measure.trim().isEmpty)
                    _WriteItYourself(
                      hint:
                          'One concrete signal that tells you this moved. Not a metric the app invents.',
                      onTap: () => showGoalEditor(context, goal: goal),
                    )
                  else
                    AppCard(
                      child: Text(goal.measure,
                          style: AppType.body.copyWith(color: t.ink)),
                    ),

                  const SectionLabel('Tasks'),
                  if (tasks.isEmpty)
                    const EmptyState(
                      title: 'No tasks yet',
                      message:
                          'Add the next concrete step below. Progress here is what fills the bar above.',
                      height: 120,
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.x14),
                      child: Column(
                        children: [
                          for (final task in tasks)
                            _GoalTaskRow(task: task, color: color),
                        ],
                      ),
                    ),
                  const SizedBox(height: Sp.x8),
                ],
              ),
            ),
            Dock(
              child: QuickAddField(
                hint: 'Add a task to this goal…',
                onSubmit: (text) => context.read<AppState>().addTask(
                      title: text,
                      pillar: goal.pillar,
                      goalId: goal.id,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WriteItYourself extends StatelessWidget {
  const _WriteItYourself({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(hint, style: AppType.meta.copyWith(color: t.muted)),
          ),
          Icon(Icons.edit_outlined, size: 16, color: t.faint),
        ],
      ),
    );
  }
}

class _GoalTaskRow extends StatelessWidget {
  const _GoalTaskRow({required this.task, required this.color});

  final Task task;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(t),
      onDismissed: (_) => context.read<AppState>().deleteTask(task.id),
      child: Padding(
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
                  style: AppType.body.copyWith(
                    color: task.done ? t.faint : t.ink,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    decorationColor: t.faint,
                  ),
                ),
              ),
            ),
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
      ),
    );
  }
}

Widget _deleteBackground(AppTokens t) => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Sp.x14),
      color: t.danger,
      child: Text('Delete',
          style: manrope(size: 12, weight: 700, color: t.dangerInk)),
    );
