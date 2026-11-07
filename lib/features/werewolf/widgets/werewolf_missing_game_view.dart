import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

/// Aktif Vampir Köylü oyunu yokken (örn. doğrudan adrese gidildiyse) gösterilen
/// güvenli boş durum.
class WerewolfMissingGameView extends StatelessWidget {
  const WerewolfMissingGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Aktif bir Vampir Köylü oyunu bulunamadı.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Vampir Köylü Kurulumuna Dön',
                variant: ButtonVariant.primary,
                fullWidth: true,
                onPressed: () => context.go(AppRouter.werewolfSetup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
