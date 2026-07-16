import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mizan_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';
import '../today/providers/daily_plan_provider.dart';

class WorkModeScreen extends StatefulWidget {
  const WorkModeScreen({super.key});

  @override
  State<WorkModeScreen> createState() => _WorkModeScreenState();
}

class _WorkModeScreenState extends State<WorkModeScreen> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyPlanProvider>();
    final task = provider.nextRecommendedTask;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.mizanText('Work Mode', 'وضع العمل'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: task == null
                  ? _AllDone(l: l)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.mizanText(
                              'Focus on one thing', 'ركّز على شيء واحد'),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.planText(task.title),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.planText(task.description),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l.mizanText(
                                    '${task.estimatedMinutes} minutes',
                                    '${task.estimatedMinutes} دقيقة',
                                  ),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  _running
                                      ? l.mizanText(
                                          'In progress', 'قيد التنفيذ')
                                      : l.mizanText('Ready', 'جاهز'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _BreakCard(
                          focusMinutes: task.estimatedMinutes,
                          l: l,
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: _running
                                  ? null
                                  : () {
                                      provider.startTask(task.id);
                                      setState(() => _running = true);
                                    },
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l.mizanText('Start', 'ابدأ')),
                            ),
                            OutlinedButton.icon(
                              onPressed: !_running
                                  ? null
                                  : () {
                                      provider.pauseTask(task.id);
                                      setState(() => _running = false);
                                    },
                              icon: const Icon(Icons.pause),
                              label: Text(l.mizanText('Pause', 'إيقاف مؤقت')),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                provider.completeTask(task.id);
                                setState(() => _running = false);
                              },
                              icon: const Icon(Icons.check),
                              label: Text(l.mizanText('Complete', 'أكمل')),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                provider.skipTask(task.id);
                                setState(() => _running = false);
                              },
                              icon: const Icon(Icons.skip_next),
                              label: Text(l.mizanText('Skip', 'تخطّ')),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakCard extends StatelessWidget {
  const _BreakCard({required this.focusMinutes, required this.l});

  final int focusMinutes;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final breakMinutes = focusMinutes > 45
        ? MizanConstants.longBreakMinutes
        : MizanConstants.shortBreakMinutes;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      leading: const Icon(Icons.free_breakfast_outlined),
      title: Text(l.mizanText('Next planned break', 'الاستراحة القادمة')),
      subtitle: Text(
        l.mizanText(
          'After $focusMinutes minutes • $breakMinutes minute break',
          'بعد $focusMinutes دقيقة • استراحة $breakMinutes دقائق',
        ),
      ),
    );
  }
}

class _AllDone extends StatelessWidget {
  const _AllDone({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.task_alt,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          l.mizanText('Priority work is clear', 'تم إنهاء العمل ذي الأولوية'),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l.mizanText(
            'There are no more incomplete priority tasks for today.',
            'لا توجد مهام أولوية غير مكتملة لليوم.',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
