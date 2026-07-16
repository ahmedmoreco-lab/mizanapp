import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/mizan_section_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/mizan_localizations.dart';
import '../../today/providers/daily_plan_provider.dart';

class RoutineProgressCard extends StatelessWidget {
  const RoutineProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyPlanProvider>();
    final routines = provider.plan.morningRoutineItems;
    final complete = routines.where((item) => item.completed).length;
    final l = AppLocalizations.of(context);

    return MizanSectionCard(
      title: l.mizanText('Morning routine', 'روتين الصباح'),
      icon: Icons.wb_sunny_outlined,
      trailing: Text('$complete/${routines.length}'),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: routines.isEmpty ? 0 : complete / routines.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 10),
          for (final item in routines)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: item.completed,
              title: Text(l.planText(item.title)),
              subtitle: Text(
                l.mizanText(
                  '${item.estimatedMinutes} min',
                  '${item.estimatedMinutes} د',
                ),
              ),
              onChanged: (value) => provider.setRoutineCompleted(
                item.id,
                value ?? false,
              ),
            ),
        ],
      ),
    );
  }
}
