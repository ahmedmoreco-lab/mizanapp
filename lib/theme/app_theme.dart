import 'package:flutter/material.dart';

import 'tokens.dart';

/// Both themes are built from the same token set, so a colour can never
/// exist in one theme and be missing in the other.
ThemeData buildTheme(AppTokens t, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: t.pillars.values.first,
    brightness: brightness,
  ).copyWith(
    surface: t.bg,
    onSurface: t.ink,
    primary: t.ink,
    onPrimary: t.btnInk,
    error: t.danger,
    onError: t.dangerInk,
    outline: t.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    fontFamily: 'Manrope',
    extensions: <ThemeExtension<dynamic>>[t],
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: t.lineSoft, thickness: 1, space: 1),
    textTheme: TextTheme(
      displaySmall: AppType.screenTitle.copyWith(color: t.ink),
      headlineSmall: AppType.subScreenTitle.copyWith(color: t.ink),
      titleMedium: AppType.cardTitle.copyWith(color: t.ink),
      titleSmall: AppType.rowTitle.copyWith(color: t.ink),
      bodyMedium: AppType.body.copyWith(color: t.ink),
      bodySmall: AppType.meta.copyWith(color: t.muted),
      labelSmall: AppType.sectionLabel.copyWith(color: t.faint),
    ),
    iconTheme: IconThemeData(color: t.muted, size: 20),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.ink,
      contentTextStyle: AppType.body.copyWith(color: t.bg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.button),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.sheet,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.sheet,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.card),
      ),
      titleTextStyle: AppType.cardTitle.copyWith(color: t.ink),
      contentTextStyle: AppType.body.copyWith(color: t.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: t.field,
      hintStyle: AppType.body.copyWith(color: t.faint),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Sp.x14,
        vertical: Sp.x14,
      ),
      border: _fieldBorder(t.line),
      enabledBorder: _fieldBorder(t.line),
      focusedBorder: _fieldBorder(t.ink),
      errorBorder: _fieldBorder(t.danger),
      focusedErrorBorder: _fieldBorder(t.danger),
    ),
  );
}

OutlineInputBorder _fieldBorder(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: c, width: 1),
    );

ThemeData get lightTheme => buildTheme(AppTokens.light, Brightness.light);
ThemeData get darkTheme => buildTheme(AppTokens.dark, Brightness.dark);
