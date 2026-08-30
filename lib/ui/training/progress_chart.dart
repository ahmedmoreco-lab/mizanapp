import 'package:flutter/material.dart';

import '../../logic/progress.dart';
import '../../theme/tokens.dart';

/// A thin progression line: three dashed rules, a soft area, and the
/// latest point emphasised. It answers "is this going up?" and nothing
/// else — analysis is not what this screen is for.
class ProgressChart extends StatelessWidget {
  const ProgressChart({
    super.key,
    required this.series,
    required this.color,
    this.height = 118,
  });

  final ChartSeries series;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => CustomPaint(
          painter: _ChartPainter(
            series: series,
            color: color,
            gridColor: t.line,
            capRing: t.card,
            progress: progress,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.color,
    required this.gridColor,
    required this.capRing,
    required this.progress,
  });

  final ChartSeries series;
  final Color color;
  final Color gridColor;
  final Color capRing;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    final points = series.points;
    if (points.length < 2) return;

    var min = points.first.value;
    var max = points.first.value;
    for (final p in points) {
      if (p.value < min) min = p.value;
      if (p.value > max) max = p.value;
    }
    // A flat series still deserves a line rather than a divide by zero.
    final span = (max - min).abs() < 0.0001 ? 1.0 : (max - min);
    final pad = span * 0.18;
    final lo = min - pad;
    final hi = max + pad;

    double yFor(double v) {
      final norm = (v - lo) / (hi - lo);
      // For pace, lower is better, so improvement still rises on screen.
      final up = series.lowerIsBetter ? 1 - norm : norm;
      return size.height - (up * size.height);
    }

    final dx = size.width / (points.length - 1);
    final all = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(i * dx, yFor(points[i].value)),
    ];

    final visible = (all.length * progress).ceil().clamp(2, all.length);
    final shown = all.sublist(0, visible);

    final line = Path()..moveTo(shown.first.dx, shown.first.dy);
    for (final p in shown.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final area = Path.from(line)
      ..lineTo(shown.last.dx, size.height)
      ..lineTo(shown.first.dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = shown.last;
    canvas.drawCircle(last, 6.2, Paint()..color = capRing);
    canvas.drawCircle(last, 4.6, Paint()..color = color);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fraction in const [0.05, 0.5, 0.95]) {
      final y = size.height * fraction;
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + 2, y), paint);
        x += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.series != series ||
      old.gridColor != gridColor;
}
