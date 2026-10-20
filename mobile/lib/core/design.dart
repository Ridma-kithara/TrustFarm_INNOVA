import 'package:flutter/material.dart';

/// TrustFarm design language.
///
/// Dark cinematic "field at night" surfaces, living emerald light, warm soil
/// gold, glass panels and display typography. The palette is deliberately
/// low-noise so the 3D scene remains the hero of every screen.
abstract final class TfColors {
  static const ink = Color(0xFF050B0F);
  static const ink2 = Color(0xFF07131A);
  static const ink3 = Color(0xFF0A1B1B);
  static const surface = Color(0xFF0E1D1E);
  static const surfaceHigh = Color(0xFF142A28);
  static const surfaceGlass = Color(0xCC0D1B1C);
  static const line = Color(0x1A9EF4D0);
  static const lineStrong = Color(0x339EF4D0);

  static const mint = Color(0xFF46E8A1);
  static const mintDeep = Color(0xFF19B97A);
  static const cyan = Color(0xFF4FD8F4);
  static const gold = Color(0xFFF5C451);
  static const soil = Color(0xFFB98A5E);

  static const text = Color(0xFFEDF8F3);
  static const textDim = Color(0xFFA9BDB6);
  static const textMuted = Color(0xFF6F8780);

  static const green = Color(0xFF41DF93);
  static const amber = Color(0xFFF0B429);
  static const red = Color(0xFFF2545B);
  static const grey = Color(0xFF7A8C87);

  static const background = RadialGradient(
    center: Alignment(-0.55, -0.9),
    radius: 1.55,
    colors: [Color(0xFF0B2320), ink2, ink],
    stops: [0, 0.55, 1],
  );
}

abstract final class TfSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const huge = 64.0;
}

abstract final class TfRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const pill = 999.0;
}

abstract final class TfMotion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const cinematic = Duration(milliseconds: 1400);
  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;
}

double motionScale(BuildContext context) {
  final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return disabled ? 0.0 : 1.0;
}

Duration motionDuration(BuildContext context, Duration duration) {
  final scale = motionScale(context);
  if (scale == 0) return Duration.zero;
  return duration;
}

TextStyle _font(
  String family,
  double size,
  FontWeight weight, {
  double? height,
  double? letterSpacing,
  Color color = TfColors.text,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
  );
}

abstract final class TfType {
  static TextStyle display(double size,
          {Color color = TfColors.text, double? height}) =>
      _font('SpaceGrotesk', size, FontWeight.w700,
          height: height ?? 1.02, letterSpacing: -0.8, color: color);

  static TextStyle headline(double size, {Color color = TfColors.text}) =>
      _font('SpaceGrotesk', size, FontWeight.w700,
          height: 1.1, letterSpacing: -0.4, color: color);

  static TextStyle title(double size, {Color color = TfColors.text}) =>
      _font('SpaceGrotesk', size, FontWeight.w600,
          height: 1.2, letterSpacing: -0.2, color: color);

  static TextStyle body(double size,
          {Color color = TfColors.textDim,
          FontWeight weight = FontWeight.w400}) =>
      _font('Inter', size, weight, height: 1.5, color: color);

  static TextStyle label(
          {Color color = TfColors.textMuted,
          double size = 11,
          FontWeight weight = FontWeight.w600}) =>
      _font('Inter', size, weight,
          height: 1.2, letterSpacing: 1.2, color: color);

  static TextStyle mono(double size,
          {Color color = TfColors.text, FontWeight weight = FontWeight.w600}) =>
      _font('SpaceGrotesk', size, weight,
          height: 1.2, letterSpacing: 0.2, color: color);
}

/// Glow used behind the primary 3D scenes and hero elements.
List<BoxShadow> glowShadow(Color color,
    {double blur = 40, double opacity = 0.35, Offset offset = Offset.zero}) {
  return [
    BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset),
  ];
}

BoxDecoration glassDecoration({
  double radius = TfRadius.lg,
  Color? color,
  Color? borderColor,
  double borderWidth = 1,
  List<BoxShadow>? shadows,
  Gradient? gradient,
}) {
  return BoxDecoration(
    color: gradient == null ? (color ?? TfColors.surfaceGlass) : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? TfColors.line, width: borderWidth),
    boxShadow: shadows ??
        const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 16)),
          BoxShadow(
              color: Color(0x14A7FFD9), blurRadius: 1, offset: Offset(0, -1)),
        ],
  );
}

Color trustColor(String? level) {
  switch (level?.toLowerCase()) {
    case 'green':
      return TfColors.green;
    case 'amber':
      return TfColors.amber;
    case 'red':
      return TfColors.red;
    default:
      return TfColors.grey;
  }
}

extension ColorX on Color {
  /// A translucent variant that works on both old and new Flutter versions.
  Color fade(double alpha) => withValues(alpha: alpha);
}
