import 'package:flutter/material.dart';

import '../../features/meals/meals_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reflection/reflection_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/today/today_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mizan_localizations.dart';

class MizanNavigationShell extends StatefulWidget {
  const MizanNavigationShell({super.key});

  @override
  State<MizanNavigationShell> createState() => _MizanNavigationShellState();
}

class _MizanNavigationShellState extends State<MizanNavigationShell> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    TodayScreen(),
    TasksScreen(),
    MealsScreen(),
    ReflectionScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [
      l.mizanText('Today', 'اليوم'),
      l.mizanText('Tasks', 'المهام'),
      l.mizanText('Meals', 'الوجبات'),
      l.mizanText('Reflection', 'التأمل'),
      l.mizanText('Profile', 'الملف الشخصي'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Mizan' : labels[_selectedIndex]),
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: labels[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: labels[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant),
            label: labels[2],
          ),
          NavigationDestination(
            icon: const Icon(Icons.nights_stay_outlined),
            selectedIcon: const Icon(Icons.nights_stay),
            label: labels[3],
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: labels[4],
          ),
        ],
      ),
    );
  }
}
