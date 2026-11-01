import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

/// Launch intro drawn above the app: the paw logo builds up pad-first, then
/// toe by toe, then the title fades in. A single tap skips it. The app
/// underneath loads in the meantime, so nothing waits on the animation.
class IntroOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const IntroOverlay({super.key, required this.child});

  @override
  ConsumerState<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends ConsumerState<IntroOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _build = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _fadeOut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    // Don't start the clock during the app's first, heavy frames: dropped
    // frames there would swallow the first parts of the animation.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      // Title font is fetched on first launch, cached afterwards.
      await GoogleFonts.pendingFonts([AppTheme.display()])
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // Offline or slow: animate with the fallback font.
    }
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted || _fadeOut.isAnimating || _removed) return;
    _build.forward().whenComplete(() {
      // Brief hold on the finished logo before fading out.
      Future.delayed(const Duration(milliseconds: 400), _finish);
    });
  }

  void _finish({bool skipped = false}) {
    if (!mounted || _fadeOut.isAnimating || _removed) return;
    if (skipped) _fadeOut.duration = const Duration(milliseconds: 150);
    _fadeOut.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _removed = true);
      ref.read(introFinishedProvider.notifier).state = true;
    });
  }

  @override
  void dispose() {
    _build.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: FadeTransition(
            opacity: ReverseAnimation(_fadeOut),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _finish(skipped: true),
              // Material (not ColoredBox) supplies a default text style; this
              // sits above the Navigator, outside any Scaffold.
              child: Material(
                color: AppColors.background,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _build,
                    builder: (context, _) => _logo(_build.value),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _logo(double t) {
    final titleT = _interval(t, 0.74, 0.95, Curves.easeOut);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 150,
          child: CustomPaint(painter: _PawPainter(t)),
        ),
        const SizedBox(height: 22),
        Opacity(
          opacity: titleT,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - titleT)),
            child: Text(
              'Cat Spotter',
              style: AppTheme.display(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Maps overall progress [t] onto a sub-interval, then applies [curve].
double _interval(double t, double begin, double end, Curve curve) =>
    curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// Paints the Material "pets" paw (24×24 units), matching the launcher icon,
/// with each part scaled in from its own centre according to progress.
class _PawPainter extends CustomPainter {
  final double t;
  _PawPainter(this.t);

  // Toes left to right: centre and radius in 24-unit icon space.
  static const _toes = [
    (Offset(4.5, 9.5), 2.5),
    (Offset(9, 5.5), 2.5),
    (Offset(15, 5.5), 2.5),
    (Offset(19.5, 9.5), 2.5),
  ];

  // Main pad, converted from the icon's SVG path to absolute coordinates.
  static final Path _pad = Path()
    ..moveTo(17.34, 14.86)
    ..cubicTo(16.47, 13.84, 15.74, 12.97, 14.86, 11.95)
    ..cubicTo(14.40, 11.41, 13.81, 10.87, 13.11, 10.63)
    ..cubicTo(13.00, 10.59, 12.89, 10.56, 12.78, 10.54)
    ..cubicTo(12.53, 10.50, 12.26, 10.50, 12.00, 10.50)
    ..cubicTo(11.74, 10.50, 11.47, 10.50, 11.21, 10.55)
    ..cubicTo(11.10, 10.57, 10.99, 10.60, 10.88, 10.64)
    ..cubicTo(10.18, 10.88, 9.60, 11.42, 9.13, 11.96)
    ..cubicTo(8.26, 12.98, 7.53, 13.85, 6.65, 14.87)
    ..cubicTo(5.34, 16.18, 3.73, 17.63, 4.03, 19.66)
    ..cubicTo(4.32, 20.68, 5.05, 21.69, 6.36, 21.98)
    ..cubicTo(7.09, 22.13, 9.42, 21.54, 11.90, 21.54)
    ..lineTo(12.08, 21.54)
    ..cubicTo(14.56, 21.54, 16.89, 22.12, 17.62, 21.98)
    ..cubicTo(18.93, 21.69, 19.66, 20.67, 19.95, 19.66)
    ..cubicTo(20.26, 17.62, 18.65, 16.17, 17.34, 14.86)
    ..close();

  static const _padCenter = Offset(12, 16.2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()..color = AppColors.accent;

    // Pad pops in first.
    final padT = _interval(t, 0.0, 0.22, Curves.easeOutBack);
    if (padT > 0) {
      canvas.save();
      canvas.translate(_padCenter.dx, _padCenter.dy);
      canvas.scale(padT);
      canvas.translate(-_padCenter.dx, -_padCenter.dy);
      canvas.drawPath(_pad, paint);
      canvas.restore();
    }

    // Then each toe, one after another from the left (~310ms apart).
    for (var i = 0; i < _toes.length; i++) {
      final start = 0.22 + i * 0.12;
      final toeT = _interval(t, start, start + 0.14, Curves.easeOutBack);
      if (toeT <= 0) continue;
      final (center, r) = _toes[i];
      canvas.drawCircle(center, r * toeT, paint);
    }
  }

  @override
  bool shouldRepaint(_PawPainter old) => old.t != t;
}
