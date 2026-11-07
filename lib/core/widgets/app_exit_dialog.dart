import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

const double _iconSize = 48;

/// Oyun sırasında geri tuşuna basıldığında / "Oyundan çık"a dokunulduğunda
/// gösterilen Neon Ink onay penceresi. TÜM oyunlarda ortaktır.
///
/// Onaylanırsa `true`, vazgeçilir ya da dışına dokunulursa `false` döner.
Future<bool> confirmExitGame(BuildContext context) async {
  final approved = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (dialogContext) => const _ExitGameDialog(),
  );
  return approved ?? false;
}

class _ExitGameDialog extends StatelessWidget {
  const _ExitGameDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
        side: const BorderSide(color: AppColors.error),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.logout,
              size: _iconSize,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'Oyundan Çık',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Oyundan çıkmak ve ilerlemeyi kaybetmek istediğinize emin '
              'misiniz?',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: 'Evet, Çık',
              variant: ButtonVariant.danger,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.s),
            AppButton(
              label: 'Oyuna Devam Et',
              variant: ButtonVariant.ghost,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
