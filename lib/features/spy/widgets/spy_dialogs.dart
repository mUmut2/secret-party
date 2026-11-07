import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_exit_dialog.dart';
import '../../../core/widgets/app_hold_button.dart';

/// "Oyundan çıkılsın mı?" onayı. Onaylanırsa `true` döner.
///
/// Tüm oyunlarla ortak Neon Ink onay penceresini kullanır.
Future<bool> confirmSpyExit(BuildContext context) => confirmExitGame(context);

/// Ajanın oyunu durdurma onayı. Yanlışlıkla basılmasın diye KİLİTLİDİR:
/// butonun basılı tutulması gerekir.
Future<bool> confirmSpyGuess(BuildContext context) {
  return _showConfirm(
    context,
    title: 'Ajan mısın?',
    message: 'Bu butona sadece ajan basmalı. Devam edersen ajan olduğun '
        'ortaya çıkar ve konumu tahmin etmen gerekir. Doğru bilirsen '
        'kazanırsın, yanlışsa masumlar kazanır.',
    confirm: (onConfirm) => AppHoldButton(
      label: 'Evet, Ajanım',
      color: AppColors.secondary,
      onConfirmed: onConfirm,
    ),
  );
}

/// Oylamaya geçiş onayı.
Future<bool> confirmSpyVoting(BuildContext context) {
  return _showConfirm(
    context,
    title: 'Oylamaya geçilsin mi?',
    message: 'Telefon sırayla herkese verilecek ve herkes ajan olduğunu '
        'düşündüğü kişiyi gizlice seçecek. Oylama başlayınca ajan artık '
        'oyunu kendisi durduramaz.',
    confirm: (onConfirm) => AppButton(
      label: 'Oylamaya Geç',
      variant: ButtonVariant.secondary,
      fullWidth: true,
      onPressed: onConfirm,
    ),
  );
}

Future<bool> _showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required Widget Function(VoidCallback onConfirm) confirm,
}) async {
  final approved = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      // Küçük ekranlarda ve büyük yazı boyutunda uzun açıklama sığmazsa
      // diyalog içeriği kaydırılabilir.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.l),
            confirm(() => Navigator.of(dialogContext).pop(true)),
            const SizedBox(height: AppSpacing.s),
            AppButton(
              label: 'Vazgeç',
              variant: ButtonVariant.ghost,
              fullWidth: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return approved ?? false;
}
