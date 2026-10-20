import 'package:flutter/material.dart';

import 'design.dart';

ThemeData buildTrustFarmTheme() {
  const scheme = ColorScheme.dark(
    primary: TfColors.mint,
    onPrimary: TfColors.ink,
    secondary: TfColors.cyan,
    onSecondary: TfColors.ink,
    tertiary: TfColors.gold,
    onTertiary: TfColors.ink,
    surface: TfColors.surface,
    onSurface: TfColors.text,
    error: TfColors.red,
    onError: TfColors.ink,
    outline: TfColors.lineStrong,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: TfColors.ink,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          bodyColor: TfColors.text,
          displayColor: TfColors.text,
          fontFamily: 'Inter',
        )
        .copyWith(
          displayLarge: TfType.display(48),
          displayMedium: TfType.display(38),
          headlineLarge: TfType.headline(30),
          headlineMedium: TfType.headline(24),
          titleLarge: TfType.title(19),
          titleMedium: TfType.title(15),
          bodyLarge: TfType.body(15),
          bodyMedium: TfType.body(13.5),
          labelLarge: TfType.label(color: TfColors.textDim),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: TfColors.textDim),
    dividerTheme:
        const DividerThemeData(color: TfColors.line, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x66152A26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TfType.body(13.5, color: TfColors.textMuted),
      labelStyle: TfType.body(13, color: TfColors.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TfRadius.md),
        borderSide: const BorderSide(color: TfColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TfRadius.md),
        borderSide:
            BorderSide(color: TfColors.mint.withValues(alpha: 0.6), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TfRadius.md),
        borderSide: const BorderSide(color: TfColors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TfRadius.md),
        borderSide: const BorderSide(color: TfColors.red, width: 1.4),
      ),
      prefixIconColor: TfColors.textMuted,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TfColors.surfaceHigh,
      contentTextStyle: TfType.body(13, color: TfColors.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TfRadius.md)),
      actionTextColor: TfColors.mint,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: TfColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TfColors.line),
      ),
      textStyle: TfType.body(11.5, color: TfColors.text),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor:
          WidgetStateProperty.all(TfColors.mint.withValues(alpha: 0.22)),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(5),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeSlideTransitionBuilder(),
        TargetPlatform.iOS: _FadeSlideTransitionBuilder(),
        TargetPlatform.macOS: _FadeSlideTransitionBuilder(),
        TargetPlatform.windows: _FadeSlideTransitionBuilder(),
        TargetPlatform.linux: _FadeSlideTransitionBuilder(),
      },
    ),
  );
}

class _FadeSlideTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) return child;
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}
