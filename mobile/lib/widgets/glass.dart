import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/design.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TfSpace.lg),
    this.radius = TfRadius.lg,
    this.blur = false,
    this.color,
    this.borderColor,
    this.gradient,
    this.shadows,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(padding: padding, child: child);
    final decorated = Container(
      decoration: glassDecoration(
        radius: radius,
        color: color,
        borderColor: borderColor,
        gradient: gradient,
        shadows: shadows,
      ),
      child: blur
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: inner,
              ),
            )
          : inner,
    );

    if (onTap == null) {
      return semanticLabel == null
          ? decorated
          : Semantics(label: semanticLabel, child: decorated);
    }
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: decorated,
        ),
      ),
    );
  }
}

class Kicker extends StatelessWidget {
  const Kicker(this.text,
      {super.key, this.color = TfColors.textMuted, this.dotColor});

  final String text;
  final Color color;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: dotColor ?? TfColors.mint,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: (dotColor ?? TfColors.mint).withValues(alpha: 0.6),
                  blurRadius: 8)
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(text.toUpperCase(), style: TfType.label(color: color)),
      ],
    );
  }
}

class GradientHeadline extends StatelessWidget {
  const GradientHeadline(this.text,
      {super.key, this.size = 40, this.textAlign = TextAlign.left});

  final String text;
  final double size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [TfColors.text, Color(0xFFD8FFF0), Color(0xFF9FE9C8)],
        stops: [0, 0.55, 1],
      ).createShader(bounds),
      child: Text(text, style: TfType.display(size), textAlign: textAlign),
    );
  }
}

class TfButton extends StatefulWidget {
  const TfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final bool secondary;

  @override
  State<TfButton> createState() => _TfButtonState();
}

class _TfButtonState extends State<TfButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final child = AnimatedContainer(
      duration: motionDuration(context, TfMotion.fast),
      curve: TfMotion.curve,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        gradient: widget.secondary
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled
                    ? const [Color(0xFF55EFA9), Color(0xFF25C987)]
                    : const [Color(0xFF2A4A3D), Color(0xFF223B33)],
              ),
        color: widget.secondary
            ? TfColors.surfaceHigh.withValues(alpha: 0.8)
            : null,
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(
          color: widget.secondary
              ? TfColors.lineStrong
              : Colors.white.withValues(alpha: 0.16),
        ),
        boxShadow: enabled && !widget.secondary
            ? [
                BoxShadow(
                    color:
                        TfColors.mint.withValues(alpha: _pressed ? 0.12 : 0.28),
                    blurRadius: _pressed ? 12 : 28),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.busy)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: TfColors.ink),
            )
          else if (widget.icon != null)
            Icon(widget.icon,
                size: 18,
                color: widget.secondary ? TfColors.text : TfColors.ink),
          if (widget.busy || widget.icon != null) const SizedBox(width: 10),
          Text(
            widget.label,
            style: TfType.body(14.5,
                    color: widget.secondary ? TfColors.text : TfColors.ink,
                    weight: FontWeight.w700)
                .copyWith(letterSpacing: 0.1),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onPressed?.call();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.975 : 1,
            duration: motionDuration(context, TfMotion.fast),
            curve: TfMotion.curve,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.55,
              duration: motionDuration(context, TfMotion.fast),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class TfIconButton extends StatefulWidget {
  const TfIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;
  final double size;

  @override
  State<TfIconButton> createState() => _TfIconButtonState();
}

class _TfIconButtonState extends State<TfIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconButton = AnimatedContainer(
      duration: motionDuration(context, TfMotion.fast),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.active
            ? TfColors.mint.withValues(alpha: 0.16)
            : TfColors.surfaceHigh.withValues(alpha: _hovered ? 0.9 : 0.65),
        shape: BoxShape.circle,
        border: Border.all(
            color: widget.active
                ? TfColors.mint.withValues(alpha: 0.5)
                : TfColors.line),
      ),
      child: Icon(
        widget.icon,
        size: 19,
        color: widget.active ? TfColors.mint : TfColors.textDim,
      ),
    );

    final button = Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.tooltip ?? widget.icon.codePoint.toString(),
      child: MouseRegion(
        cursor: widget.onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(onTap: widget.onPressed, child: iconButton),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

class DeltaPill extends StatelessWidget {
  const DeltaPill(
      {super.key,
      required this.label,
      required this.icon,
      required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TfType.body(10.5, color: color, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.decimals = 0,
  });

  final double? value;
  final TextStyle style;
  final String suffix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    if (value == null) return Text('—', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: motionDuration(context, const Duration(milliseconds: 850)),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text('${animatedValue.toStringAsFixed(decimals)}$suffix',
            style: style);
      },
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.kicker,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? kicker;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kicker != null) ...[
                Kicker(kicker!),
                const SizedBox(height: 8),
              ],
              Text(title, style: TfType.headline(22)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: TfType.body(13, color: TfColors.textMuted)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MetaballDot extends StatelessWidget {
  const MetaballDot(
      {super.key, required this.color, this.size = 8, this.pulse = true});

  final Color color;
  final double size;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: motionDuration(context, const Duration(milliseconds: 1400)),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: pulse ? scale : 1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.65), blurRadius: 9)
              ],
            ),
          ),
        );
      },
    );
  }
}

class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.child, this.scale = 1.012});

  final Widget child;
  final double scale;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? widget.scale : 1,
        duration: motionDuration(context, TfMotion.base),
        curve: TfMotion.curve,
        child: AnimatedSlide(
          offset: _hovered ? const Offset(0, -0.006) : Offset.zero,
          duration: motionDuration(context, TfMotion.base),
          curve: TfMotion.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
