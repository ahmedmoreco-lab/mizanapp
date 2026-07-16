import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';
import '../../providers/locale_provider.dart';
import '../today/providers/daily_plan_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyPlanProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final profile = provider.profile;
    final l = AppLocalizations.of(context);
    final time = MaterialLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(
                          profile.name.characters.first,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              l.mizanText(
                                'Local prototype profile',
                                'ملف تجريبي محلي',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.mizanText('Language', 'اللغة'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'en',
                            label: Text(l.mizanText('English', 'الإنجليزية')),
                          ),
                          ButtonSegment(
                            value: 'ar',
                            label: Text(l.mizanText('Arabic', 'العربية')),
                          ),
                        ],
                        selected: {localeProvider.locale.languageCode},
                        onSelectionChanged: (selection) =>
                            localeProvider.setLocale(Locale(selection.first)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.mizanText('Daily rhythm', 'إيقاع اليوم'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: Text(
                            l.mizanText('Normal wake time', 'وقت الاستيقاظ')),
                        trailing:
                            Text(time.formatTimeOfDay(profile.normalWakeTime)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.work_outline),
                        title: Text(l.mizanText('Work hours', 'ساعات العمل')),
                        trailing: Text(
                          '${time.formatTimeOfDay(profile.workStartTime)} – '
                          '${time.formatTimeOfDay(profile.workEndTime)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.mizanText('Goals', 'الأهداف'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final goal in profile.goals)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.flag_outlined),
                          title: Text(goal),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
