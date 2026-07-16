import 'package:flutter/material.dart';

import '../../core/models/mizan_enums.dart';
import '../../core/models/wake_up_assessment.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';

class WakeUpCheckInResult {
  const WakeUpCheckInResult.assessment(this.assessment) : snoozed = false;
  const WakeUpCheckInResult.snoozed()
      : assessment = null,
        snoozed = true;

  final WakeUpAssessment? assessment;
  final bool snoozed;
}

class WakeUpCheckInDialog extends StatefulWidget {
  const WakeUpCheckInDialog({super.key});

  @override
  State<WakeUpCheckInDialog> createState() => _WakeUpCheckInDialogState();
}

class _WakeUpCheckInDialogState extends State<WakeUpCheckInDialog> {
  bool _showAssessment = false;
  SleepQuality _sleepQuality = SleepQuality.average;
  EnergyLevel _energyLevel = EnergyLevel.medium;
  DayType _dayType = DayType.workday;
  TrainingPlan _trainingPlan = TrainingPlan.undecided;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _showAssessment
              ? _buildAssessment(context, l)
              : _buildWakePrompt(context, l),
        ),
      ),
    );
  }

  Widget _buildWakePrompt(BuildContext context, AppLocalizations l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.wb_sunny_outlined,
            size: 34,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l.mizanText('Good morning', 'صباح الخير'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l.mizanText(
            'A quick check-in will shape today’s local plan.',
            'تسجيل سريع سيساعد في تشكيل خطة اليوم المحلية.',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _showAssessment = true),
          child: Text(l.mizanText('I’m awake', 'أنا مستيقظ')),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.pop(
            context,
            const WakeUpCheckInResult.snoozed(),
          ),
          child: Text(l.mizanText('Snooze 15 minutes', 'غفوة 15 دقيقة')),
        ),
        TextButton(
          onPressed: () => setState(() => _showAssessment = true),
          child: Text(l.mizanText('Adjust today', 'عدّل خطة اليوم')),
        ),
      ],
    );
  }

  Widget _buildAssessment(BuildContext context, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.mizanText('How should today feel?', 'كيف تريد أن يكون يومك؟'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        _ChoiceField<SleepQuality>(
          label: l.mizanText('Sleep quality', 'جودة النوم'),
          value: _sleepQuality,
          choices: {
            SleepQuality.poor: l.mizanText('Poor', 'ضعيفة'),
            SleepQuality.average: l.mizanText('Average', 'متوسطة'),
            SleepQuality.good: l.mizanText('Good', 'جيدة'),
          },
          onChanged: (value) => setState(() => _sleepQuality = value),
        ),
        _ChoiceField<EnergyLevel>(
          label: l.mizanText('Energy', 'الطاقة'),
          value: _energyLevel,
          choices: {
            EnergyLevel.low: l.mizanText('Low', 'منخفضة'),
            EnergyLevel.medium: l.mizanText('Medium', 'متوسطة'),
            EnergyLevel.high: l.mizanText('High', 'مرتفعة'),
          },
          onChanged: (value) => setState(() => _energyLevel = value),
        ),
        _ChoiceField<DayType>(
          label: l.mizanText('Day type', 'نوع اليوم'),
          value: _dayType,
          choices: {
            DayType.workday: l.mizanText('Workday', 'يوم عمل'),
            DayType.freeDay: l.mizanText('Free day', 'يوم حر'),
          },
          onChanged: (value) => setState(() => _dayType = value),
        ),
        _ChoiceField<TrainingPlan>(
          label: l.mizanText('Training', 'التمرين'),
          value: _trainingPlan,
          choices: {
            TrainingPlan.training: l.mizanText('Training', 'تمرين'),
            TrainingPlan.rest: l.mizanText('Rest', 'راحة'),
            TrainingPlan.undecided: l.mizanText('Undecided', 'لم أقرر'),
          },
          onChanged: (value) => setState(() => _trainingPlan = value),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            WakeUpCheckInResult.assessment(
              WakeUpAssessment(
                sleepQuality: _sleepQuality,
                energyLevel: _energyLevel,
                dayType: _dayType,
                trainingPlan: _trainingPlan,
              ),
            ),
          ),
          child: Text(l.mizanText('Refresh my plan', 'حدّث خطتي')),
        ),
      ],
    );
  }
}

class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in choices.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: entry.key == value,
                  onSelected: (_) => onChanged(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
