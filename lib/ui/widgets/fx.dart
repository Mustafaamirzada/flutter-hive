import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-screen ambient background: slowly drifting aurora blobs over the
/// midnight canvas. Cheap: 3 radial-gradient circles re-painted per frame.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, this.intensity = 1.0});

  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
      lowerBound: 0,
      upperBound: 2 * math.pi,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: MediaQuery.sizeOf(context),
            painter: _AuroraPainter(
              _controller.value,
              widget.intensity * context.tone.blobAlpha,
              baseColor: context.tone.canvas,
            ),
          );
        },
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.alpha, {required this.baseColor});

  final double t; // 0..2*pi
  final double alpha; // base blob opacity multiplier for this brightness
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Base canvas first - this is the "main container" color of every screen.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = baseColor,
    );
    final blobs = <_Blob>[
      _Blob(
        base: Offset(size.width * 0.12, size.height * 0.16),
        radius: math.min(size.width, size.height) * 0.55,
        color: AuroraPalette.violet,
        drift: size.height * 0.05,
        phase: 0,
      ),
      _Blob(
        base: Offset(size.width * 0.92, size.height * 0.08),
        radius: math.min(size.width, size.height) * 0.6,
        color: AuroraPalette.cyan,
        drift: size.height * 0.04,
        phase: 2.1,
      ),
      _Blob(
        base: Offset(size.width * 0.62, size.height * 0.38),
        radius: math.min(size.width, size.height) * 0.42,
        color: AuroraPalette.pink,
        drift: size.height * 0.07,
        phase: 4.4,
      ),
      // A faint one bottom-right so the never-felt-dead bottom calm area.
      _Blob(
        base: Offset(size.width * 0.85, size.height * 0.85),
        radius: math.min(size.width, size.height) * 0.45,
        color: const Color(0xFF312E81),
        drift: size.height * 0.03,
        phase: 1.2,
      ),
    ];

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    for (final blob in blobs) {
      final offset = Offset(
        blob.base.dx + math.sin(t + blob.phase) * blob.drift,
        blob.base.dy + math.cos(t * 0.8 + blob.phase) * blob.drift,
      );
      paint.shader = RadialGradient(
        colors: [
          blob.color.withValues(alpha: 0.34 * alpha),
          blob.color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: offset, radius: blob.radius));
      canvas.drawCircle(offset, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _Blob {
  const _Blob({
    required this.base,
    required this.radius,
    required this.color,
    required this.drift,
    required this.phase,
  });

  final Offset base;
  final double radius;
  final Color color;
  final double drift;
  final double phase;
}

/// Frosted glass panel used across all screens.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? tone.panelBorder, width: 1),
        boxShadow: [
          BoxShadow(color: tone.shadowColor.withValues(alpha: 0.06), blurRadius: 18),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Text painted with the aurora gradient.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient, // null -> tone-aware aurora text gradient
  });

  final String text;
  final TextStyle? style;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final effective = gradient ?? context.tone.textGradient;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => effective.createShader(bounds),
      child: Text(
        text,
        style: (style ?? Theme.of(context).textTheme.headlineSmall)
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Staggered entrance: fades/slides/scales its child in, delayed by its
/// [order] so lists cascade naturally.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child, this.order = 0});

  final Widget child;
  final int order;

  static const double _delayStep = 0.08;

  @override
  Widget build(BuildContext context) {
    final delay = (order * _delayStep).clamp(0.0, 0.64);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: (480 + delay * 900).round()),
      curve: _DelayedEaseOutCubic(delay),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 26),
            child: Transform.scale(
              scale: 0.965 + 0.035 * t,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _DelayedEaseOutCubic extends Curve {
  const _DelayedEaseOutCubic(this.delay);
  final double delay;

  @override
  double transformInternal(double t) {
    final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }
}

/// Animated gradient ring gauge; [child] renders in the center.
class GradientGauge extends StatelessWidget {
  const GradientGauge({
    super.key,
    required this.value, // 0..1
    this.size = 64,
    this.stroke = 7,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) {
        return CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
            value: animated,
            stroke: stroke,
            trackColor: context.tone.gaugeTrack,
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.stroke,
    required this.trackColor,
  });

  final double value;
  final double stroke;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (value <= 0) return;
    final sweep = 2 * math.pi * value;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep * 1.35,
        tileMode: TileMode.clamp,
        colors: AuroraPalette.auroraGradient,
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}
