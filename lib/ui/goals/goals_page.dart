import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/goal.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'goal_detail_page.dart';
import 'goal_edit_sheet.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;

    final live = app.goals.where((g) => g.status.isLive).toList();
    final dormant = app.goals
        .where((g) =>
            g.status == GoalStatus.notStarted || g.status == GoalStatus.parked)
        .toList();
    final done = app.goals.where((g) => g.status == GoalStatus.done).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x6, Sp.x20, Sp.x8),
            children: [
              ScreenTitle(
                'Goals',
                eyebrow: app.goals.isEmpty
                    ? 'Nothing yet'
                    : '${live.length + dormant.length} active · ${done.length} done',
              ),
              if (app.goals.isEmpty) ...[
                const SectionLabel('Start here'),
                const EmptyState(
                  title: 'No goals yet',
                  message:
                      'A goal is worth adding when you can say why it matters and how you\'ll know it moved.',
                ),
              ],
              if (live.isNotEmpty) ...[
                const SectionLabel('In progress'),
                for (final g in live) _GoalCard(goal: g),
              ],
              if (dormant.isNotEmpty) ...[
                const SectionLabel('Not moving'),
                for (final g in dormant) _GoalCard(goal: g),
              ],
              if (done.isNotEmpty) ...[
                const SectionLabel('Done'),
                for (final g in done) _GoalCard(goal: g),
              ],
              const SizedBox(height: Sp.x8),
            ],
          ),
        ),
        Dock(
          child: PrimaryButton(
            'New goal',
            onPressed: () => showGoalEditor(context),
          ),
        ),
      ],
    ).withBackground(t.bg);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final progress = app.progressForGoal(goal.id);

    // Dormant goals go grey. The list sorts itself into live and dormant
    // without needing to reorder anything.
    final accent = goal.status.isLive || goal.status == GoalStatus.done
        ? t.pillar(goal.pillar)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.x10),
      child: AppCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GoalDetailPage(goalId: goal.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PillarDot(goal.pillar),
                const SizedBox(width: Sp.x10),
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.cardTitle.copyWith(color: t.ink),
                  ),
                ),
                const SizedBox(width: Sp.x8),
                TintPill(goal.status.label, color: accent),
              ],
            ),
            const SizedBox(height: Sp.x10),
            ThinBar(
              value: progress.fraction,
              height: 5,
              color: accent ?? t.faint,
            ),
            const SizedBox(height: Sp.x8),
            Row(
              children: [
                Expanded(
                  child: Text(progress.label,
                      style: AppType.meta.copyWith(color: t.muted)),
                ),
                Text(_trailing(goal, t),
                    style: AppType.meta.copyWith(color: t.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A parked goal reports how long it has been parked instead of a target
  /// date. The system says what you are avoiding rather than hiding it.
  String _trailing(Goal goal, AppTokens t) {
    if (goal.status == GoalStatus.parked) {
      final since = goal.statusChangedAt;
      if (since != null) {
        final days = DateTime.now().difference(since).inDays;
        return days <= 0 ? 'Parked today' : 'Parked $days days';
      }
      return 'Parked';
    }
    final target = goal.targetDate;
    if (target == null) return 'No target date';
    return 'Target · ${DateFormat('d MMM').format(target)}';
  }
}
