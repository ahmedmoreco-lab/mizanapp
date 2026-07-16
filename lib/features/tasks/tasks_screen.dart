import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/mizan_enums.dart';
import '../../core/widgets/mizan_section_card.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';
import '../today/providers/daily_plan_provider.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyPlanProvider>();
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: MizanSectionCard(
            title: l.mizanText('Today’s priorities', 'أولويات اليوم'),
            icon: Icons.checklist,
            child: Column(
              children: [
                for (final task in provider.plan.priorityTasks)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: task.status == TaskStatus.completed,
                      onChanged: task.status == TaskStatus.skipped
                          ? null
                          : (value) => value ?? false
                              ? provider.completeTask(task.id)
                              : provider.pauseTask(task.id),
                    ),
                    title: Text(
                      l.planText(task.title),
                      style: TextStyle(
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(l.planText(task.description)),
                    trailing: Chip(
                      label: Text(
                        task.status == TaskStatus.skipped
                            ? l.mizanText('Skipped', 'تم التخطي')
                            : l.mizanText(
                                '${task.estimatedMinutes} min',
                                '${task.estimatedMinutes} د',
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
