/// One recorded performance. Every field is optional because a strength
/// set, a run and a skill rep-max fill in different ones.
class SetEntry {
  SetEntry({
    required this.id,
    required this.setIndex,
    this.weightKg,
    this.reps,
    this.distanceKm,
    this.durationSec,
    this.rpe,
  });

  final String id;
  final int setIndex;
  final double? weightKg;
  final int? reps;
  final double? distanceKm;
  final int? durationSec;
  final int? rpe;

  bool get isEmpty =>
      weightKg == null &&
      reps == null &&
      distanceKm == null &&
      durationSec == null;

  SetEntry copyWith({
    int? setIndex,
    double? weightKg,
    bool clearWeight = false,
    int? reps,
    bool clearReps = false,
    double? distanceKm,
    bool clearDistance = false,
    int? durationSec,
    bool clearDuration = false,
    int? rpe,
    bool clearRpe = false,
  }) =>
      SetEntry(
        id: id,
        setIndex: setIndex ?? this.setIndex,
        weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
        reps: clearReps ? null : (reps ?? this.reps),
        distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
        durationSec: clearDuration ? null : (durationSec ?? this.durationSec),
        rpe: clearRpe ? null : (rpe ?? this.rpe),
      );

  /// "92.5 kg × 5" for strength, "8.20 km · 44:10" for a run.
  String summary() {
    final parts = <String>[];
    if (weightKg != null) parts.add('${_num(weightKg!)} kg');
    if (reps != null) {
      parts.add(weightKg != null ? '× $reps' : '$reps reps');
    }
    if (distanceKm != null) parts.add('${distanceKm!.toStringAsFixed(2)} km');
    if (durationSec != null && distanceKm != null) {
      parts.add(formatClock(durationSec!));
    }
    if (parts.isEmpty && durationSec != null) parts.add(formatClock(durationSec!));
    return parts.join(' ');
  }

  /// Pace in seconds per km, or null when it cannot be worked out.
  double? get paceSecPerKm {
    final d = distanceKm;
    final t = durationSec;
    if (d == null || t == null || d <= 0) return null;
    return t / d;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'set_index': setIndex,
        'weight_kg': weightKg,
        'reps': reps,
        'distance_km': distanceKm,
        'duration_sec': durationSec,
        'rpe': rpe,
      };

  static SetEntry fromJson(Map<String, Object?> r) => SetEntry(
        id: r['id']! as String,
        setIndex: (r['set_index'] as int?) ?? 1,
        weightKg: (r['weight_kg'] as num?)?.toDouble(),
        reps: r['reps'] as int?,
        distanceKm: (r['distance_km'] as num?)?.toDouble(),
        durationSec: r['duration_sec'] as int?,
        rpe: r['rpe'] as int?,
      );
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

String formatPace(double secPerKm) {
  final m = secPerKm ~/ 60;
  final s = (secPerKm % 60).round();
  return '$m:${s.toString().padLeft(2, '0')}';
}
