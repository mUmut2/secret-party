import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_shadows.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/turkish_text.dart';

const Duration _defaultHoldDuration = Duration(milliseconds: 900);
const double _borderWidth = 1.5;
const double _lockIconSize = 18;

/// "Basılı tut ve onayla" butonu.
///
/// Telefon elden ele geçerken gizli bilgiyi koruyan kilitli onaydır: tek bir
/// dokunuş yetmez, buton [holdDuration] boyunca basılı tutulmalıdır. Basılı
/// tutuldukça zemin soldan sağa dolar; parmak erken kalkarsa dolum geri
/// sarılır ve hiçbir şey olmaz. Tamamlanınca güçlü bir titreşim verir.
///
/// Ekran okuyucu kullanıcıları için çift dokunuş da onaylar (erişilebilirlik).
class AppHoldButton extends ConsumerStatefulWidget {
  const AppHoldButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color = AppColors.primary,
    this.holdDuration = _defaultHoldDuration,
  });

  final String label;
  final VoidCallback onConfirmed;

  /// Dolum ve çerçeve rengi.
  final Color color;
  final Duration holdDuration;

  @override
  ConsumerState<AppHoldButton> createState() => _AppHoldButtonState();
}

class _AppHoldButtonState extends ConsumerState<AppHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onStatus);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    ref.read(hapticServiceProvider).heavyImpact();
    ref.read(audioServiceProvider).tap();
    _controller.value = 0;
    widget.onConfirmed();
  }

  void _start() {
    ref.read(hapticServiceProvider).selectionClick();
    _controller.forward();
  }

  void _cancel() {
    if (_controller.isCompleted) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Semantics(
      button: true,
      label: '${widget.label}. Onaylamak için basılı tut.',
      excludeSemantics: true,
      onTap: widget.onConfirmed,
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            final textColor =
                progress > 0.5 ? AppColors.onPrimary : AppColors.textPrimary;
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.m),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: color, width: _borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: AppShadows.glow(color, 0.15 + 0.35 * progress),
                      blurRadius: 12 + 12 * progress,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: ColoredBox(color: color),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.m,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            progress > 0 ? Icons.lock_open : Icons.lock,
                            size: _lockIconSize,
                            color: textColor,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Flexible(
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.fast,
                              style: AppTypography.label.copyWith(
                                color: textColor,
                              ),
                              child: Text(
                                widget.label.toUpperTr(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
