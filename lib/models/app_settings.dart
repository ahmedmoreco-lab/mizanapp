import 'package:flutter/material.dart';

import 'pillar.dart';

class AppSettings {
  AppSettings({
    this.themeMode = ThemeMode.system,
    Set<Pillar>? suggestingPillars,
    this.lastFocusConfirmedOn,
  }) : suggestingPillars = suggestingPillars ??
            Pillar.values.where((p) => p.suggestedByDefault).toSet();

  final ThemeMode themeMode;

  /// Pillars the Home suggestion engine is allowed to surface.
  /// Aspirational pillars stay taggable but sit this out.
  final Set<Pillar> suggestingPillars;

  /// Date (midnight) on which today's focus was last confirmed.
  final DateTime? lastFocusConfirmedOn;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Set<Pillar>? suggestingPillars,
    DateTime? lastFocusConfirmedOn,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        suggestingPillars: suggestingPillars ?? this.suggestingPillars,
        lastFocusConfirmedOn: lastFocusConfirmedOn ?? this.lastFocusConfirmedOn,
      );

  Map<String, Object?> toJson() => {
        'theme_mode': themeMode.name,
        'suggesting_pillars': suggestingPillars.map((p) => p.key).toList(),
        'last_focus_confirmed_on': lastFocusConfirmedOn?.millisecondsSinceEpoch,
      };

  static AppSettings fromJson(Map<String, Object?> r) {
    final raw = (r['suggesting_pillars'] as List?)?.cast<String>();
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == r['theme_mode'],
        orElse: () => ThemeMode.system,
      ),
      suggestingPillars: raw?.map(PillarX.fromKey).toSet(),
      lastFocusConfirmedOn: r['last_focus_confirmed_on'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              r['last_focus_confirmed_on']! as int),
    );
  }
}
