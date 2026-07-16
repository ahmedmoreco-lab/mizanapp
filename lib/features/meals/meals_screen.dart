import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/mizan_section_card.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';
import '../today/providers/daily_plan_provider.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meal = context.watch<DailyPlanProvider>().plan.mealDirection;
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: MizanSectionCard(
            title: l.planText(meal.title),
            icon: Icons.restaurant_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.planText(meal.description)),
                const SizedBox(height: 18),
                _GuidanceRow(
                  icon: Icons.egg_alt_outlined,
                  label: l.mizanText('Protein', 'البروتين'),
                  value: l.planText(meal.proteinGuidance),
                ),
                _GuidanceRow(
                  icon: Icons.rice_bowl_outlined,
                  label: l.mizanText('Carbohydrate', 'الكربوهيدرات'),
                  value: l.planText(meal.carbohydrateGuidance),
                ),
                _GuidanceRow(
                  icon: Icons.eco_outlined,
                  label: l.mizanText('Vegetables', 'الخضروات'),
                  value: l.planText(meal.vegetableGuidance),
                ),
                _GuidanceRow(
                  icon: Icons.water_drop_outlined,
                  label: l.mizanText('Fats', 'الدهون'),
                  value: l.planText(meal.fatGuidance),
                ),
                const Divider(height: 30),
                Text(l.planText(meal.notes)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
