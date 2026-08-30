import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'goals/goals_page.dart';
import 'home/home_page.dart';
import 'profile/profile_page.dart';
import 'training/training_page.dart';

/// Persistent tab bar, four destinations, never hidden. Recognition over
/// recall: nothing in the app moves.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = <_Destination>[
    _Destination('Home', Icons.home_outlined, Icons.home_rounded),
    _Destination('Goals', Icons.adjust_outlined, Icons.adjust_rounded),
    _Destination('Training', Icons.fitness_center_outlined,
        Icons.fitness_center_rounded),
    _Destination('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            HomePage(),
            GoalsPage(),
            TrainingPage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: t.bar,
          border: Border(top: BorderSide(color: t.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: Sp.x8, bottom: Sp.x6),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _TabButton(
                      destination: _destinations[i],
                      selected: i == _index,
                      onTap: () => setState(() => _index = i),
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

class _Destination {
  const _Destination(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = selected ? t.ink : t.faint;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? destination.activeIcon : destination.icon,
                size: 21, color: color),
            const SizedBox(height: Sp.x4),
            Text(destination.label,
                style: AppType.tabLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
