import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/turkish_text.dart';
import 'app_hold_button.dart';

const double _phoneIconSize = 64;

/// Telefon elden ele geçerken gösterilen KİLİTLİ ekran (tüm pass-and-play
/// oyunlarında ortak: Vampir Köylü, Ajan).
///
/// Ekranda yalnızca sıradaki oyuncunun adı ve kilitli onay butonu bulunur;
/// hiçbir rol bilgisi yoktur. Buton basılı tutulmadan ekran açılmaz, böylece
/// telefonu uzatan kişi ya da yanlışlıkla dokunan biri gizli bilgiyi göremez.
class AppPassGate extends StatelessWidget {
  const AppPassGate({
    super.key,
    required this.playerName,
    required this.instruction,
    required this.onUnlocked,
    this.accentColor = AppColors.primary,
    this.progressLabel,
  });

  final String playerName;

  /// Kilidin üstündeki kısa yönerge (örn. "Telefonu al ve gizlice ekranı aç").
  final String instruction;
  final VoidCallback onUnlocked;
  final Color accentColor;

  /// Sıra göstergesi, örn. "3/7".
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1),
                duration: AppMotion.slow,
                curve: AppMotion.standardCurve,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progressLabel != null) ...[
                      Text(
                        progressLabel!,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                    ],
                    Icon(
                      Icons.phonelink_lock,
                      size: _phoneIconSize,
                      color: accentColor,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'Telefonu ${playerName.withDativeSuffix()} Ver',
                      textAlign: TextAlign.center,
                      style: AppTypography.display.copyWith(
                        shadows: [
                          Shadow(
                            color: AppShadows.glow(accentColor, 0.5),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      '$playerName, $instruction',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    const Text(
                      'Ekranı sadece sen gör. Diğerleri bakmasın.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        AppHoldButton(
          label: 'Ben $playerName · Basılı Tut',
          color: accentColor,
          onConfirmed: onUnlocked,
        ),
      ],
    );
  }
}
