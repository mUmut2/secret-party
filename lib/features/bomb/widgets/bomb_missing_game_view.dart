import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

/// Aktif Tik Tak Bomba oyunu yokken (örn. doğrudan adrese gidildiyse)
/// gösterilen güvenli boş durum.
class BombMissingGameView extends StatelessWidget {
  const BombMissingGameView({super.key});

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
                'Aktif bir Tik Tak Bomba oyunu bulunamadı.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Kuruluma Dön',
                variant: ButtonVariant.warning,
                fullWidth: true,
                onPressed: () => context.go(AppRouter.bombSetup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
