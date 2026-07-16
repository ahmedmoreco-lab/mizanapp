import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mizan_constants.dart';
import '../../core/models/mizan_enums.dart';
import '../../core/widgets/mizan_section_card.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';
import '../onboarding/wake_up_check_in_dialog.dart';
import '../routines/widgets/routine_progress_card.dart';
import '../work_mode/work_mode_screen.dart';
import 'providers/daily_plan_provider.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyPlanProvider>();
    final plan = provider.plan;
    final l = AppLocalizations.of(context);
    final localizations = MaterialLocalizations.of(context);
    final percentage = (plan.completionPercentage * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(
                              l, DateTime.now().hour, provider.profile.name),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          localizations.formatFullDate(plan.date),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: l.mizanText('Wake-up check-in', 'تسجيل الاستيقاظ'),
                    onPressed: () => _openWakeUpCheckIn(context, provider, l),
                    icon: const Icon(Icons.notifications_active_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.mizanText('Today’s main goal', 'هدف اليوم الرئيسي'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.planText(plan.mainGoal),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: plan.completionPercentage,
                              minHeight: 10,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (provider.wakeUpAssessment != null) ...[
                const SizedBox(height: 12),
                _AssessmentSummary(provider: provider, l: l),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: provider.nextRecommendedTask == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const WorkModeScreen(),
                          ),
                        ),
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l.mizanText('Start Work Mode', 'ابدأ وضع العمل')),
              ),
              const SizedBox(height: 16),
              const RoutineProgressCard(),
              const SizedBox(height: 16),
              MizanSectionCard(
                title: l.mizanText('Top three tasks', 'أهم ثلاث مهام'),
                icon: Icons.task_alt_outlined,
                child: Column(
                  children: [
                    for (final task in plan.priorityTasks.take(
                      MizanConstants.topTaskCount,
                    ))
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: task.status == TaskStatus.completed,
                        title: Text(l.planText(task.title)),
                        subtitle: Text(
                          l.mizanText(
                            '${task.estimatedMinutes} min',
                            '${task.estimatedMinutes} د',
                          ),
                        ),
                        onChanged: (complete) {
                          if (complete ?? false) {
                            provider.completeTask(task.id);
                          } else {
                            provider.pauseTask(task.id);
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              MizanSectionCard(
                title: l.mizanText('Meal direction', 'اتجاه الوجبة'),
                icon: Icons.restaurant_menu,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.planText(plan.mealDirection.title),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(l.planText(plan.mealDirection.description)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              MizanSectionCard(
                title: l.mizanText(
                    'Useful free-time idea', 'فكرة مفيدة لوقت الفراغ'),
                icon: Icons.auto_awesome_outlined,
                child: Text(l.planText(plan.suggestedActivity)),
              ),
              const SizedBox(height: 16),
              MizanSectionCard(
                title: l.mizanText('Evening reflection', 'التأمل المسائي'),
                icon: Icons.nights_stay_outlined,
                child: Row(
                  children: [
                    Icon(
                      provider.reflection == null
                          ? Icons.radio_button_unchecked
                          : Icons.check_circle,
                      color: provider.reflection == null
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.reflection == null
                            ? l.mizanText(
                                'Not completed yet',
                                'لم يكتمل بعد',
                              )
                            : l.mizanText(
                                'Reflection completed',
                                'اكتمل التأمل',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(AppLocalizations l, int hour, String name) {
    final greeting = switch (hour) {
      < 12 => l.mizanText('Good morning', 'صباح الخير'),
      < 18 => l.mizanText('Good afternoon', 'مساء الخير'),
      _ => l.mizanText('Good evening', 'مساء الخير'),
    };
    return '$greeting, $name';
  }

  Future<void> _openWakeUpCheckIn(
    BuildContext context,
    DailyPlanProvider provider,
    AppLocalizations l,
  ) async {
    final result = await showDialog<WakeUpCheckInResult>(
      context: context,
      builder: (_) => const WakeUpCheckInDialog(),
    );
    if (!context.mounted || result == null) return;
    if (result.snoozed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.mizanText(
              'Wake-up check-in snoozed for 15 minutes.',
              'تم تأجيل تسجيل الاستيقاظ 15 دقيقة.',
            ),
          ),
        ),
      );
      return;
    }
    final assessment = result.assessment;
    if (assessment != null) provider.applyWakeUpAssessment(assessment);
  }
}

class _AssessmentSummary extends StatelessWidget {
  const _AssessmentSummary({required this.provider, required this.l});

  final DailyPlanProvider provider;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final assessment = provider.wakeUpAssessment!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.bedtime_outlined, size: 18),
          label: Text(_sleepLabel(assessment.sleepQuality)),
        ),
        Chip(
          avatar: const Icon(Icons.bolt_outlined, size: 18),
          label: Text(_energyLabel(assessment.energyLevel)),
        ),
        Chip(
          avatar: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(
            assessment.dayType == DayType.workday
                ? l.mizanText('Workday', 'يوم عمل')
                : l.mizanText('Free day', 'يوم حر'),
          ),
        ),
      ],
    );
  }

  String _sleepLabel(SleepQuality quality) => switch (quality) {
        SleepQuality.poor => l.mizanText('Poor sleep', 'نوم ضعيف'),
        SleepQuality.average => l.mizanText('Average sleep', 'نوم متوسط'),
        SleepQuality.good => l.mizanText('Good sleep', 'نوم جيد'),
      };

  String _energyLabel(EnergyLevel energy) => switch (energy) {
        EnergyLevel.low => l.mizanText('Low energy', 'طاقة منخفضة'),
        EnergyLevel.medium => l.mizanText('Medium energy', 'طاقة متوسطة'),
        EnergyLevel.high => l.mizanText('High energy', 'طاقة مرتفعة'),
      };
}
