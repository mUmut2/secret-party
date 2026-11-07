import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/app_card.dart';
import '../utils/settings_labels.dart';
import '../viewmodels/game_settings_notifier.dart';
import 'game_settings_sheet.dart';

const double _leadingIconSize = 24;

/// Oyuncu Kurulumu ekranındaki tek satırlık ayar özeti
/// ("Karışık · 3 dk", ipucu açıksa "Karışık · 3 dk · İpuçlu").
/// Dokununca ayarlar penceresi açılır; varsayılanlarla da oyun başlatılabilir.
class SettingsSummaryCard extends ConsumerWidget {
  const SettingsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameSettingsProvider);
    final summary = [
      categoryLabel(settings.selectedCategoryId),
      durationLabel(settings.roundDurationSeconds),
      if (settings.giveImposterHint) 'İpuçlu',
    ].join(' · ');

    return Semantics(
      button: true,
      label: 'Oyun ayarları: $summary. Değiştirmek için dokunun.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showGameSettingsSheet(context),
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.m,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.tune,
                color: AppColors.primary,
                size: _leadingIconSize,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Oyun Ayarları', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Değiştir'.toUpperTr(),
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
