/// The eight fixed life pillars. Order here is the order they appear
/// everywhere in the app.
enum Pillar { work, training, faith, family, learning, personal, content, rest }

extension PillarX on Pillar {
  String get label => switch (this) {
        Pillar.work => 'Work',
        Pillar.training => 'Training',
        Pillar.faith => 'Faith',
        Pillar.family => 'Family',
        Pillar.learning => 'Learning',
        Pillar.personal => 'Personal',
        Pillar.content => 'Content',
        Pillar.rest => 'Rest',
      };

  /// Stored in the database. Never change these strings.
  String get key => name;

  /// Pillars that start switched out of the daily suggestion engine.
  /// Aspirational pillars would otherwise win the neglect score every
  /// morning and train you to ignore the Home screen.
  bool get suggestedByDefault => switch (this) {
        Pillar.personal || Pillar.content || Pillar.rest => false,
        _ => true,
      };

  static Pillar fromKey(String key) =>
      Pillar.values.firstWhere((p) => p.name == key, orElse: () => Pillar.personal);
}
