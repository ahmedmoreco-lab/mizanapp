import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/pillar.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import 'pillars_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final stats = app.trainingStats;
    final color = t.pillar(Pillar.training);
    final onCount = app.settings.suggestingPillars.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x8, Sp.x20, Sp.x24),
      children: [
        const ScreenTitle('Profile'),

        const SectionLabel('Streak'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${stats.currentStreak}',
                      style: AppType.bigNumber.copyWith(color: color)),
                  const SizedBox(width: Sp.x8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        stats.currentStreak == 0
                            ? 'no streak yet — log a workout to start one'
                            : 'day${stats.currentStreak == 1 ? '' : 's'} in a row with something logged',
                        style: AppType.meta.copyWith(color: t.muted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.x14),
              _WeekStrip(days: stats.weekDays, color: color),
            ],
          ),
        ),

        const SectionLabel('Totals'),
        Row(
          children: [
            Expanded(child: _Stat(value: stats.total, label: 'Workouts')),
            const SizedBox(width: Sp.x8),
            Expanded(
                child: _Stat(value: app.completedGoals, label: 'Goals done')),
            const SizedBox(width: Sp.x8),
            Expanded(child: _Stat(value: stats.thisMonth, label: 'This month')),
          ],
        ),

        const SectionLabel('Settings'),
        _SettingsList(
          children: [
            _SettingRow(
              title: 'Pillars',
              subtitle: '$onCount of ${Pillar.values.length} feed daily suggestions',
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: t.faint),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PillarsPage()),
              ),
            ),
            _SettingRow(
              title: 'Theme',
              trailing: _ThemeSegments(
                value: app.themeMode,
                onChanged: (m) => context.read<AppState>().setThemeMode(m),
              ),
            ),
            const _SettingRow(
              title: 'Reminders',
              subtitle: 'Not in v1 — decide once the habit sticks',
              enabled: false,
            ),
            const _SettingRow(
              title: 'Data',
              subtitle: 'On this device · cloud sync not set up',
            ),
            _SettingRow(
              title: 'Re-import from Notion',
              subtitle: app.hasImportedNotion
                  ? 'Replaces goals and tasks with the bundled snapshot'
                  : 'Load the HI Ahmed snapshot — 7 goals, 18 tasks',
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: t.faint),
              onTap: () => _reimport(context),
            ),
            _SettingRow(
              title: 'Re-import training plan',
              subtitle: 'Replaces templates and the exercise library',
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: t.faint),
              onTap: () => _reimportPlan(context),
            ),
            _SettingRow(
              title: 'Export everything',
              subtitle: 'Copies your full JSON to the clipboard',
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: t.faint),
              onTap: () => _export(context),
            ),
            _SettingRow(
              title: 'Erase everything',
              subtitle: 'Wipes this device. There is no undo.',
              danger: true,
              onTap: () => _erase(context),
            ),
          ],
        ),

        const SizedBox(height: Sp.x20),
        Center(
          child: Text('Ahmed OS · v1.0.0',
              style: AppType.meta.copyWith(color: t.faint, fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _reimport(BuildContext context) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-import from Notion?'),
        content: const Text(
            'Goals and tasks are replaced by the bundled snapshot. Anything '
            'you have added or ticked off here since the last import is lost. '
            'Training data is left alone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final count = await app.importNotionSnapshot();
    messenger.showSnackBar(
      SnackBar(content: Text('Imported $count goals and tasks')),
    );
  }

  Future<void> _reimportPlan(BuildContext context) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reload the training cycle?'),
        content: const Text(
            'Templates and the exercise library are replaced by the bundled '
            'plan. Sessions you have already logged are kept, and any '
            'exercise they use is archived rather than removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final count = await app.importTrainingPlan();
    messenger.showSnackBar(
      SnackBar(content: Text('Loaded $count workout templates')),
    );
  }

  Future<void> _export(BuildContext context) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: app.exportJson()));
    messenger.showSnackBar(
      const SnackBar(content: Text('Copied your data as JSON')),
    );
  }

  Future<void> _erase(BuildContext context) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase everything?'),
        content: const Text(
            'Every task, goal and workout on this device. Export first if you want a copy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Erase', style: TextStyle(color: context.t.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await app.eraseEverything();
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, required this.color});

  final List<bool> days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;

    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    // Today is an outline, not a fill — it isn't earned yet.
                    color: days[i]
                        ? color
                        : (i == todayIndex ? Colors.transparent : t.track),
                    border: !days[i] && i == todayIndex
                        ? Border.all(color: color, width: 1.6)
                        : null,
                    borderRadius: BorderRadius.circular(Rad.chip),
                  ),
                ),
                const SizedBox(height: Sp.x6),
                Text(labels[i],
                    style: manrope(size: 10, weight: 700, color: t.faint)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: AppType.statNumber.copyWith(color: t.ink)),
          const SizedBox(height: 1),
          Text(label,
              style: manrope(size: 11.5, weight: 600, color: t.muted)),
        ],
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(Rad.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: t.lineSoft),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // A disabled row reads as a decision you made, not a feature missing.
    final titleColor = !enabled ? t.faint : (danger ? t.danger : t.ink);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Sp.x14, vertical: Sp.x14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: manrope(
                            size: 14.5, weight: 600, color: titleColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(subtitle!,
                          style: AppType.meta
                              .copyWith(color: enabled ? t.muted : t.faint)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Sp.x10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSegments extends StatelessWidget {
  const _ThemeSegments({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    const labels = ['System', 'Light', 'Dark'];

    return Container(
      width: 172,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.track,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (var i = 0; i < modes.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(modes[i]),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: modes[i] == value ? t.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(labels[i],
                      style: manrope(
                          size: 12,
                          weight: 700,
                          color: modes[i] == value ? t.ink : t.muted)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
