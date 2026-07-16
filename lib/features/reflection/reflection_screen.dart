import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/daily_reflection.dart';
import '../../core/models/mizan_enums.dart';
import '../../core/widgets/mizan_section_card.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';
import '../today/providers/daily_plan_provider.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _achievement = TextEditingController();
  final _difficulty = TextEditingController();
  final _lesson = TextEditingController();
  final _adjustment = TextEditingController();
  bool _mainGoalCompleted = false;
  EnergyLevel _energy = EnergyLevel.medium;
  MoodLevel _mood = MoodLevel.good;

  @override
  void dispose() {
    _achievement.dispose();
    _difficulty.dispose();
    _lesson.dispose();
    _adjustment.dispose();
    super.dispose();
  }

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
            title: provider.reflection == null
                ? l.mizanText('Close the day', 'اختتم يومك')
                : l.mizanText('Today is reflected', 'تم تسجيل تأمل اليوم'),
            icon: Icons.nights_stay_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _mainGoalCompleted,
                  title: Text(
                    l.mizanText(
                      'I completed the main goal',
                      'أنجزت الهدف الرئيسي',
                    ),
                  ),
                  onChanged: (value) => setState(
                    () => _mainGoalCompleted = value,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l.mizanText('Energy', 'الطاقة')),
                _EnumChoices<EnergyLevel>(
                  selected: _energy,
                  labels: {
                    EnergyLevel.low: l.mizanText('Low', 'منخفضة'),
                    EnergyLevel.medium: l.mizanText('Medium', 'متوسطة'),
                    EnergyLevel.high: l.mizanText('High', 'مرتفعة'),
                  },
                  onSelected: (value) => setState(() => _energy = value),
                ),
                const SizedBox(height: 14),
                Text(l.mizanText('Mood', 'المزاج')),
                _EnumChoices<MoodLevel>(
                  selected: _mood,
                  labels: {
                    MoodLevel.low: l.mizanText('Low', 'منخفض'),
                    MoodLevel.neutral: l.mizanText('Neutral', 'محايد'),
                    MoodLevel.good: l.mizanText('Good', 'جيد'),
                    MoodLevel.great: l.mizanText('Great', 'رائع'),
                  },
                  onSelected: (value) => setState(() => _mood = value),
                ),
                const SizedBox(height: 18),
                _ReflectionField(
                  controller: _achievement,
                  label: l.mizanText('Best achievement', 'أفضل إنجاز'),
                ),
                _ReflectionField(
                  controller: _difficulty,
                  label: l.mizanText('Main difficulty', 'أهم صعوبة'),
                ),
                _ReflectionField(
                  controller: _lesson,
                  label: l.mizanText('Lesson learned', 'ما الذي تعلمته'),
                ),
                _ReflectionField(
                  controller: _adjustment,
                  label: l.mizanText(
                    'Adjustment for tomorrow',
                    'تعديل الغد',
                  ),
                ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: () {
                    provider.saveReflection(
                      DailyReflection(
                        date: provider.plan.date,
                        mainGoalCompleted: _mainGoalCompleted,
                        energyLevel: _energy,
                        mood: _mood,
                        achievement: _achievement.text.trim(),
                        difficulty: _difficulty.text.trim(),
                        lesson: _lesson.text.trim(),
                        tomorrowAdjustment: _adjustment.text.trim(),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l.mizanText(
                            'Reflection saved locally.',
                            'تم حفظ التأمل محلياً.',
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l.mizanText('Save reflection', 'احفظ التأمل')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnumChoices<T> extends StatelessWidget {
  const _EnumChoices({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  final T selected;
  final Map<T, String> labels;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: entry.key == selected,
            onSelected: (_) => onSelected(entry.key),
          ),
      ],
    );
  }
}

class _ReflectionField extends StatelessWidget {
  const _ReflectionField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
