import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../data/privacy_policy_content.dart';

/// Gizlilik Politikası (KVKK / GDPR bilgilendirmesi).
///
/// Metin [PrivacyPolicyContent]'ten gelir; aynı metin
/// `docs/gizlilik-politikasi.html` olarak web'de de yayınlanır.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(PrivacyPolicyContent.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Ayarlara dön',
          onPressed: () => context.go(AppRouter.settings),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            const AppCard(
              variant: CardVariant.highlighted,
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primary),
                  SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      PrivacyPolicyContent.summary,
                      style: AppTypography.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              PrivacyPolicyContent.lastUpdatedLine,
              style: AppTypography.caption,
            ),
            for (final section in PrivacyPolicyContent.sections) ...[
              const SizedBox(height: AppSpacing.l),
              Text(section.title, style: AppTypography.title),
              const SizedBox(height: AppSpacing.s),
              Text(section.body, style: AppTypography.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
