import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart'; // AppSpacing + AppRadius

/// Kart varyantları.
///
/// - [standard]: normal içerik kartı (subtle shadow)
/// - [elevated]: modal / dialog gibi üst katman
/// - [highlighted]: seçili / vurgulanan / olumlu durum (lime çerçeve + glow)
/// - [danger]: tehlike / kayıp durumu (kırmızı çerçeve + glow)
/// - [night]: gece temalı ekranlar (lacivert zemin, mor çerçeve + glow)
enum CardVariant { standard, elevated, highlighted, danger, night }

const double _emphasisBorderWidth = 1.5;

/// Uygulamadaki TEK kart bileşeni.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = CardVariant.standard,
    this.padding = const EdgeInsets.all(AppSpacing.m),
  });

  final Widget child;
  final CardVariant variant;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final _CardStyleSpec spec = _resolveStyle(variant);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: BorderRadius.circular(spec.radius),
        border: spec.border,
        boxShadow: spec.shadow,
      ),
      child: child,
    );
  }

  _CardStyleSpec _resolveStyle(CardVariant variant) {
    switch (variant) {
      case CardVariant.standard:
        return const _CardStyleSpec(
          backgroundColor: AppColors.surface,
          radius: AppRadius.l,
          border: null,
          shadow: AppShadows.subtle,
        );
      case CardVariant.elevated:
        return const _CardStyleSpec(
          backgroundColor: AppColors.surfaceElevated,
          radius: AppRadius.xl,
          border: null,
          shadow: AppShadows.elevated,
        );
      case CardVariant.highlighted:
        return _CardStyleSpec(
          backgroundColor: AppColors.surface,
          radius: AppRadius.l,
          border: Border.all(
            color: AppColors.primary,
            width: _emphasisBorderWidth,
          ),
          shadow: AppShadows.glowPrimary,
        );
      case CardVariant.danger:
        return _CardStyleSpec(
          backgroundColor: AppColors.surface,
          radius: AppRadius.l,
          border: Border.all(
            color: AppColors.error,
            width: _emphasisBorderWidth,
          ),
          shadow: AppShadows.glowError,
        );
      case CardVariant.night:
        return _CardStyleSpec(
          backgroundColor: AppColors.nightSurface,
          radius: AppRadius.l,
          border: Border.all(
            color: AppColors.nightAccent,
            width: _emphasisBorderWidth,
          ),
          shadow: AppShadows.glowNight,
        );
    }
  }
}

class _CardStyleSpec {
  const _CardStyleSpec({
    required this.backgroundColor,
    required this.radius,
    required this.border,
    required this.shadow,
  });

  final Color backgroundColor;
  final double radius;
  final Border? border;
  final List<BoxShadow>? shadow;
}
