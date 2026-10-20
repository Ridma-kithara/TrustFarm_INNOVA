import 'package:flutter/material.dart';

import '../core/design.dart';
import '../core/formatters.dart';
import 'glass.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.cachedAt,
    required this.onRetry,
    this.retrying = false,
  });

  final DateTime? cachedAt;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: TfColors.amber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(TfRadius.md),
        border: Border.all(color: TfColors.amber.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 17, color: TfColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cachedAt == null
                  ? 'Offline — showing the last saved state.'
                  : 'Offline — last saved state from ${timeAgo(cachedAt)}.',
              style: TfType.body(12, color: TfColors.textDim),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: retrying ? null : onRetry,
            style: TextButton.styleFrom(
              foregroundColor: TfColors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: retrying
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: TfColors.amber),
                  )
                : const Text('Retry',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassPanel(
          padding: const EdgeInsets.all(TfSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: TfColors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: TfColors.red.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.wifi_tethering_error_rounded,
                    color: TfColors.red, size: 24),
              ),
              const SizedBox(height: 18),
              Text('Connection interrupted',
                  style: TfType.headline(20), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: TfType.body(13, color: TfColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 22),
              TfButton(
                  label: 'Try again',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(TfSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      TfColors.mint.withValues(alpha: 0.18),
                      Colors.transparent
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: TfColors.line),
                ),
                child: Icon(icon, color: TfColors.mint, size: 28),
              ),
              const SizedBox(height: 18),
              Text(title,
                  style: TfType.headline(20), textAlign: TextAlign.center),
              const SizedBox(height: 7),
              Text(message,
                  style: TfType.body(13, color: TfColors.textMuted),
                  textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: const [
                Color(0xFF13241F),
                Color(0xFF1D3830),
                Color(0xFF13241F),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Reading the field'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TfSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration:
                  motionDuration(context, const Duration(milliseconds: 1500)),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          TfColors.mint.withValues(alpha: 0.28),
                          TfColors.mint.withValues(alpha: 0.02),
                        ],
                      ),
                      border: Border.all(
                          color: TfColors.mint.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                            color: TfColors.mint.withValues(alpha: 0.25),
                            blurRadius: 36)
                      ],
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: TfColors.mint, size: 30),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('$message…',
                style: TfType.body(13, color: TfColors.textMuted)),
            const SizedBox(height: 20),
            const SizedBox(width: 180, child: ShimmerBox(height: 4, radius: 2)),
          ],
        ),
      ),
    );
  }
}

class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.message,
    this.color = TfColors.cyan,
    this.icon = Icons.info_outline_rounded,
    this.action,
  });

  final String message;
  final Color color;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(TfRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TfType.body(12, color: TfColors.textDim))),
          if (action != null) action!,
        ],
      ),
    );
  }
}
