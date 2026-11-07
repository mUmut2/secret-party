import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// Çizim oranları (bombanın kenar uzunluğuna göre).
const double _bodyCenterX = 0.44;
const double _bodyCenterY = 0.6;
const double _bodyRadius = 0.34;
const double _strokeRatio = 0.03;
const double _capWidth = 0.18;
const double _capHeight = 0.12;
const double _fuseEndX = 0.86;
const double _fuseEndY = 0.12;
const double _sparkRadius = 0.05;
const double _sparkRayLength = 0.07;
const int _sparkRayCount = 8;
const double _highlightAlpha = 0.18;
const double _sparkGlowAlpha = 0.35;

/// Paketsiz, CustomPainter ile çizilen Neon Ink bombası.
///
/// [lit] açıkken fitilin ucunda kıvılcım parlar. Renk tek başına anlam
/// taşımasın diye ekranlar bombanın yanında açık metin de gösterir.
class BombGraphic extends StatelessWidget {
  const BombGraphic({super.key, required this.size, this.lit = true});

  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _BombPainter(lit: lit),
      ),
    );
  }
}

class _BombPainter extends CustomPainter {
  const _BombPainter({required this.lit});

  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * _strokeRatio;
    final center = Offset(s * _bodyCenterX, s * _bodyCenterY);
    final radius = s * _bodyRadius;

    // Fitil: kapaktan sağ üst köşeye kıvrılan çizgi.
    final capCenter = center +
        Offset.fromDirection(-math.pi / 4, radius + s * _capHeight / 2);
    final fuseEnd = Offset(s * _fuseEndX, s * _fuseEndY);
    final fusePath = Path()
      ..moveTo(capCenter.dx, capCenter.dy)
      ..quadraticBezierTo(
        fuseEnd.dx - s * 0.02,
        capCenter.dy - s * 0.02,
        fuseEnd.dx,
        fuseEnd.dy,
      );
    canvas.drawPath(
      fusePath,
      Paint()
        ..color = AppColors.textSecondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Kapak (45° döndürülmüş dikdörtgen).
    canvas
      ..save()
      ..translate(capCenter.dx, capCenter.dy)
      ..rotate(math.pi / 4);
    final capRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: s * _capWidth,
        height: s * _capHeight,
      ),
      Radius.circular(stroke),
    );
    canvas
      ..drawRRect(capRect, Paint()..color = AppColors.surface)
      ..drawRRect(
        capRect,
        Paint()
          ..color = AppColors.warning
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      )
      ..restore();

    // Gövde.
    canvas
      ..drawCircle(center, radius, Paint()..color = AppColors.surfaceElevated)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.warning
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      )
      // Parlama.
      ..drawCircle(
        center + Offset(-radius * 0.4, -radius * 0.4),
        radius * 0.22,
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: _highlightAlpha),
      );

    if (!lit) return;

    // Kıvılcım: parlayan çekirdek + ışınlar.
    canvas.drawCircle(
      fuseEnd,
      s * _sparkRadius * 2,
      Paint()
        ..color = AppColors.warning.withValues(alpha: _sparkGlowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * _sparkRadius),
    );
    final rayPaint = Paint()
      ..color = AppColors.warning
      ..strokeWidth = stroke * 0.7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _sparkRayCount; i++) {
      final angle = i * 2 * math.pi / _sparkRayCount;
      canvas.drawLine(
        fuseEnd + Offset.fromDirection(angle, s * _sparkRadius),
        fuseEnd +
            Offset.fromDirection(angle, s * (_sparkRadius + _sparkRayLength)),
        rayPaint,
      );
    }
    canvas.drawCircle(
      fuseEnd,
      s * _sparkRadius * 0.8,
      Paint()..color = AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_BombPainter oldDelegate) => oldDelegate.lit != lit;
}
