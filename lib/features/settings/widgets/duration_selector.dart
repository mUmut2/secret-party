import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../utils/settings_labels.dart';

/// Tur süresi için segmentli seçici (Segmented Control).
///
/// Seçili segment lime dolgu + koyu metin alır. Ekran okuyucu için ayrıca
/// "seçili" bilgisi verilir (renk tek başına anlam taşımaz).
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.options,
    required this.selectedSeconds,
    required this.onSelected,
  });

  final List<int> options;
  final int selectedSeconds;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Row(
        children: [
          for (final seconds in options)
            Expanded(
              child: _DurationSegment(
                label: durationLabel(seconds),
                isSelected: seconds == selectedSeconds,
                onTap: () => onSelected(seconds),
              ),
            ),
        ],
      ),
    );
  }
}

class _DurationSegment extends StatelessWidget {
  const _DurationSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Oyun süresi $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.label.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
