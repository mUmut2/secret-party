import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/services/game_engine_notifier.dart';
import '../viewmodels/game_settings_notifier.dart';
import '../viewmodels/game_settings_state.dart';
import 'category_selector.dart';
import 'duration_selector.dart';

const double _handleWidth = 40;
const double _handleHeight = 4;

/// Oyun ayarları penceresini (bottom sheet) açar.
Future<void> showGameSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
    ),
    builder: (_) => const GameSettingsSheet(),
  );
}

/// Süre, kategori ve Imposter ipucu seçimlerinin yapıldığı pencere.
///
/// Seçimler anında [gameSettingsProvider]'a yazılır; "Tamam" sadece pencereyi
/// kapatır. İçerik kaydırılabilir olduğu için küçük ekranlarda taşmaz.
class GameSettingsSheet extends ConsumerWidget {
  const GameSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameSettingsProvider);
    final notifier = ref.read(gameSettingsProvider.notifier);
    final categoryIds = ref.watch(wordRepositoryProvider).categoryIds;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: _handleWidth,
                height: _handleHeight,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text('Oyun Ayarları', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.l),
            const Text('Oyun Süresi', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'İpucu verme turunun süresi.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            DurationSelector(
              options: GameSettingsState.durationOptions,
              selectedSeconds: settings.roundDurationSeconds,
              onSelected: notifier.selectDuration,
            ),
            const SizedBox(height: AppSpacing.l),
            const Text('Kategori', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Karışık seçilirse her oyunda kategori rastgele gelir.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            CategorySelector(
              categoryIds: categoryIds,
              selectedCategoryId: settings.selectedCategoryId,
              onSelected: notifier.selectCategory,
            ),
            const SizedBox(height: AppSpacing.l),
            _ImposterHintToggle(
              value: settings.giveImposterHint,
              onChanged: notifier.setGiveImposterHint,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: 'Tamam',
              variant: ButtonVariant.primary,
              fullWidth: true,
              // Pencere, go_router rotası değil; kendi Navigator'ı ile kapanır.
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Imposter'a ipucu ver" anahtarı ve açıklaması.
class _ImposterHintToggle extends StatelessWidget {
  const _ImposterHintToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: value ? AppColors.primary : AppColors.textDisabled,
          ),
          const SizedBox(width: AppSpacing.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Imposter'a ipucu ver", style: AppTypography.title),
                SizedBox(height: AppSpacing.xs),
                Text(
                  "Imposter'a gizli kelimeyle ilgili tek kelimelik bir ipucu "
                  'gösterilir.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}
