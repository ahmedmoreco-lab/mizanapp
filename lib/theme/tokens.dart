import 'package:flutter/material.dart';

import '../models/pillar.dart';

/// Spacing scale. Nothing in the app uses a value that isn't on it.
abstract final class Sp {
  static const double x2 = 2;
  static const double x4 = 4;
  static const double x6 = 6;
  static const double x8 = 8;
  static const double x10 = 10;
  static const double x14 = 14;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
}

abstract final class Rad {
  static const double card = 14;
  static const double button = 13;
  static const double chip = 9;
  static const double badge = 9;
  static const double sheet = 22;
  static const double bar = 2;
}

/// Manrope is bundled as a variable font, so weight is set through the
/// wght axis rather than relying on the platform to pick a face.
TextStyle manrope({
  required double size,
  required double weight,
  double? height,
  double? letterSpacing,
  Color? color,
  bool tabular = false,
}) {
  return TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation('wght', weight)],
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

FontWeight _weight(double w) {
  if (w >= 800) return FontWeight.w800;
  if (w >= 700) return FontWeight.w700;
  if (w >= 600) return FontWeight.w600;
  if (w >= 500) return FontWeight.w500;
  return FontWeight.w400;
}

/// The one type scale.
abstract final class AppType {
  static TextStyle get screenTitle =>
      manrope(size: 28, weight: 800, height: 1.12, letterSpacing: -0.56);
  static TextStyle get subScreenTitle =>
      manrope(size: 21, weight: 800, height: 1.2, letterSpacing: -0.32);
  static TextStyle get bigNumber => manrope(
      size: 40, weight: 800, height: 0.95, letterSpacing: -1.2, tabular: true);
  static TextStyle get statNumber => manrope(
      size: 23, weight: 800, height: 1.1, letterSpacing: -0.46, tabular: true);
  static TextStyle get metricNumber => manrope(
      size: 20, weight: 800, height: 1.1, letterSpacing: -0.4, tabular: true);
  static TextStyle get cardTitle => manrope(size: 16, weight: 700, height: 1.3);
  static TextStyle get rowTitle => manrope(size: 15, weight: 700, height: 1.3);
  static TextStyle get body => manrope(size: 14.5, weight: 500, height: 1.45);
  static TextStyle get setValue =>
      manrope(size: 14.5, weight: 600, height: 1.3, tabular: true);
  static TextStyle get meta => manrope(size: 12.5, weight: 500, height: 1.35);
  static TextStyle get sectionLabel =>
      manrope(size: 10.5, weight: 700, height: 1.3, letterSpacing: 1.37);
  static TextStyle get tabLabel => manrope(size: 10, weight: 700, height: 1.2);
  static TextStyle get button => manrope(size: 15, weight: 700, height: 1.2);
  static TextStyle get chip => manrope(size: 12.5, weight: 600, height: 1.2);
}

/// Every colour the app uses, for one theme. Components read these and
/// never hard-code a value, so light and dark stay in step.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.card,
    required this.line,
    required this.lineSoft,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.field,
    required this.track,
    required this.bar,
    required this.sheet,
    required this.danger,
    required this.dangerInk,
    required this.btn,
    required this.btnInk,
    required this.btnOff,
    required this.btnOffInk,
    required this.pillars,
    required this.tint,
    required this.onAccent,
  });

  final Color bg;
  final Color card;
  final Color line;
  final Color lineSoft;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color field;
  final Color track;
  final Color bar;
  final Color sheet;
  final Color danger;
  final Color dangerInk;
  final Color btn;
  final Color btnInk;
  final Color btnOff;
  final Color btnOffInk;
  final Map<Pillar, Color> pillars;

  /// Opacity used for an accent-tinted background.
  final double tint;

  /// Text/icon colour that sits on a full-strength accent fill.
  final Color onAccent;

  Color pillar(Pillar p) => pillars[p] ?? ink;
  Color pillarTint(Pillar p) => pillar(p).withValues(alpha: tint);

  static const light = AppTokens(
    bg: Color(0xFFF4F5F6),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE4E6E9),
    lineSoft: Color(0xFFEEF0F2),
    ink: Color(0xFF15171A),
    muted: Color(0xFF6A6F76),
    faint: Color(0xFFA0A5AC),
    field: Color(0xFFFFFFFF),
    track: Color(0xFFE7E9EC),
    bar: Color(0xFFFFFFFF),
    sheet: Color(0xFFFFFFFF),
    danger: Color(0xFFB23B2E),
    dangerInk: Color(0xFFFFFFFF),
    btn: Color(0xFF15171A),
    btnInk: Color(0xFFFFFFFF),
    btnOff: Color(0xFFE4E6E9),
    btnOffInk: Color(0xFFA0A5AC),
    tint: 0.14,
    onAccent: Color(0xFFFFFFFF),
    pillars: {
      Pillar.work: Color(0xFF4C63C7),
      Pillar.training: Color(0xFFC9553D),
      Pillar.faith: Color(0xFF2E8B6F),
      Pillar.family: Color(0xFFC08525),
      Pillar.learning: Color(0xFF2F7FB0),
      Pillar.personal: Color(0xFF8B4FA8),
      Pillar.content: Color(0xFFC24A6E),
      Pillar.rest: Color(0xFF5F7D78),
    },
  );

  static const dark = AppTokens(
    bg: Color(0xFF0F1113),
    card: Color(0xFF17191C),
    line: Color(0xFF26292E),
    lineSoft: Color(0xFF202327),
    ink: Color(0xFFEDEEF0),
    muted: Color(0xFF9298A0),
    faint: Color(0xFF666C74),
    field: Color(0xFF1C1F23),
    track: Color(0xFF26292E),
    bar: Color(0xFF141619),
    sheet: Color(0xFF1A1D20),
    danger: Color(0xFFD9604F),
    dangerInk: Color(0xFF120806),
    btn: Color(0xFFEDEEF0),
    btnInk: Color(0xFF0F1113),
    btnOff: Color(0xFF26292E),
    btnOffInk: Color(0xFF666C74),
    tint: 0.20,
    onAccent: Color(0xFF0F1113),
    pillars: {
      Pillar.work: Color(0xFF8B9BE8),
      Pillar.training: Color(0xFFE88A70),
      Pillar.faith: Color(0xFF5FBE9E),
      Pillar.family: Color(0xFFE0AC5A),
      Pillar.learning: Color(0xFF6BAEDA),
      Pillar.personal: Color(0xFFBC8ADA),
      Pillar.content: Color(0xFFE58BAC),
      Pillar.rest: Color(0xFF93AFA9),
    },
  );

  @override
  AppTokens copyWith({
    Color? bg,
    Color? card,
    Color? line,
    Color? lineSoft,
    Color? ink,
    Color? muted,
    Color? faint,
    Color? field,
    Color? track,
    Color? bar,
    Color? sheet,
    Color? danger,
    Color? dangerInk,
    Color? btn,
    Color? btnInk,
    Color? btnOff,
    Color? btnOffInk,
    Map<Pillar, Color>? pillars,
    double? tint,
    Color? onAccent,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      field: field ?? this.field,
      track: track ?? this.track,
      bar: bar ?? this.bar,
      sheet: sheet ?? this.sheet,
      danger: danger ?? this.danger,
      dangerInk: dangerInk ?? this.dangerInk,
      btn: btn ?? this.btn,
      btnInk: btnInk ?? this.btnInk,
      btnOff: btnOff ?? this.btnOff,
      btnOffInk: btnOffInk ?? this.btnOffInk,
      pillars: pillars ?? this.pillars,
      tint: tint ?? this.tint,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get t =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
