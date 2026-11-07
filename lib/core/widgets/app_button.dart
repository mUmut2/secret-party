import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart'; // AppSpacing + AppRadius
import '../theme/app_typography.dart';
import '../utils/turkish_text.dart';

/// Buton varyantları.
///
/// - [primary]: ana CTA (lime, glow)
/// - [secondary]: ikincil aksiyon (fuşya, glow)
/// - [outlined]: şeffaf zemin, lime çerçeve
/// - [ghost]: zeminsiz, sadece metin
/// - [danger]: olumsuz / cezalı aksiyon (kırmızı, glow) — örn. "TABU!"
/// - [warning]: dikkat isteyen nötr aksiyon (kehribar, glow) — örn. "PAS"
/// - [night]: gece temalı ekranların ana aksiyonu (mor, glow)
enum ButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  danger,
  warning,
  night,
}

const double _pressedScale = 0.96;
const double _outlinedBorderWidth = 1.5;
const double _disabledBorderWidth = 1;

/// Uygulamadaki TEK buton bileşeni. `onPressed: null` ise pasif durumdadır.
///
/// Dokunulduğunda varsayılan olarak hafif bir titreşim (`lightImpact`) ve
/// (Ayarlar'da açıksa) dokunma sesi verir.
/// Aksiyonun kendisi daha güçlü bir geri bildirim tetikliyorsa (örneğin rol
/// açıklama) iki titreşim üst üste binmesin diye [haptics] `false` yapılır.
class AppButton extends ConsumerStatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.fullWidth = false,
    this.haptics = true,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool fullWidth;

  /// Dokunuşta `lightImpact` tetiklensin mi?
  final bool haptics;

  /// Yan yana dizilen dar butonlar için (örn. Tabu'daki TABU! · PAS · DOĞRU):
  /// daha dar yatay iç boşluk ve TEK SATIR etiket. Etiket sığmazsa satıra
  /// kırılmak yerine orantılı küçülür; büyük sistem yazı boyutunda bile buton
  /// yüksekliği sabit kalır.
  final bool dense;

  @override
  ConsumerState<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends ConsumerState<AppButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;

  void _handleTap() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    if (widget.haptics) {
      ref.read(hapticServiceProvider).lightImpact();
    }
    ref.read(audioServiceProvider).tap();
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final _ButtonStyleSpec spec = _resolveStyle(widget.variant, _isDisabled);

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      child: GestureDetector(
        onTapDown:
            _isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: _isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            _isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: _isDisabled ? null : _handleTap,
        child: AnimatedScale(
          scale: _isPressed && !AppMotion.reduceMotion(context)
              ? _pressedScale
              : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standardCurve,
            width: widget.fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.dense ? AppSpacing.s : AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            decoration: BoxDecoration(
              color: spec.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.m),
              border: spec.border,
              boxShadow: (_isPressed || _isDisabled) ? null : spec.shadow,
            ),
            alignment: Alignment.center,
            child: widget.dense
                ? FittedBox(fit: BoxFit.scaleDown, child: _label(spec))
                : _label(spec),
          ),
        ),
      ),
    );
  }

  Widget _label(_ButtonStyleSpec spec) {
    return Text(
      widget.label.toUpperTr(),
      textAlign: TextAlign.center,
      maxLines: widget.dense ? 1 : null,
      style: AppTypography.label.copyWith(color: spec.textColor),
    );
  }

  _ButtonStyleSpec _resolveStyle(ButtonVariant variant, bool disabled) {
    if (disabled) {
      return _ButtonStyleSpec(
        backgroundColor: AppColors.surface,
        textColor: AppColors.textDisabled,
        border: Border.all(
          color: AppColors.divider,
          width: _disabledBorderWidth,
        ),
        shadow: null,
      );
    }

    switch (variant) {
      case ButtonVariant.primary:
        return const _ButtonStyleSpec(
          backgroundColor: AppColors.primary,
          textColor: AppColors.onPrimary,
          border: null,
          shadow: AppShadows.glowPrimary,
        );
      case ButtonVariant.secondary:
        return const _ButtonStyleSpec(
          backgroundColor: AppColors.secondary,
          textColor: AppColors.onPrimary,
          border: null,
          shadow: AppShadows.glowSecondary,
        );
      case ButtonVariant.outlined:
        return _ButtonStyleSpec(
          backgroundColor: AppColors.transparent,
          textColor: AppColors.primary,
          border: Border.all(
            color: AppColors.primary,
            width: _outlinedBorderWidth,
          ),
          shadow: null,
        );
      case ButtonVariant.ghost:
        return const _ButtonStyleSpec(
          backgroundColor: AppColors.transparent,
          textColor: AppColors.textSecondary,
          border: null,
          shadow: null,
        );
      case ButtonVariant.danger:
        // Kırmızı zeminde koyu metin: WCAG AA kontrastı (5.6:1). Beyaz metin
        // 3.2:1 ile AA'yı geçemiyordu.
        return const _ButtonStyleSpec(
          backgroundColor: AppColors.error,
          textColor: AppColors.onPrimary,
          border: null,
          shadow: AppShadows.glowError,
        );
      case ButtonVariant.warning:
        return const _ButtonStyleSpec(
          backgroundColor: AppColors.warning,
          textColor: AppColors.onPrimary,
          border: null,
          shadow: AppShadows.glowWarning,
        );
      case ButtonVariant.night:
        return const _ButtonStyleSpec(
          backgroundColor: AppColors.nightAccent,
          textColor: AppColors.onPrimary,
          border: null,
          shadow: AppShadows.glowNight,
        );
    }
  }
}

class _ButtonStyleSpec {
  const _ButtonStyleSpec({
    required this.backgroundColor,
    required this.textColor,
    required this.border,
    required this.shadow,
  });

  final Color backgroundColor;
  final Color textColor;
  final Border? border;
  final List<BoxShadow>? shadow;
}
