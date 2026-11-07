import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Tabu kurulumundaki segmentli seçici (süre, pas hakkı, hedef skor).
///
/// Seçili segment lime dolgu + koyu metin alır; ekran okuyucuya ayrıca
/// "seçili" bilgisi verilir (renk tek başına anlam taşımaz).
class TabooOptionSelector extends ConsumerWidget {
  const TabooOptionSelector({
    super.key,
    required this.semanticPrefix,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  /// Ekran okuyucu etiketi ön eki, örn. "Tur süresi".
  final String semanticPrefix;
  final List<int> options;
  final int selected;
  final String Function(int value) labelOf;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Row(
        children: [
          for (final value in options)
            Expanded(
              child: _Segment(
                label: labelOf(value),
                semanticLabel: '$semanticPrefix ${labelOf(value)}',
                isSelected: value == selected,
                onTap: () {
                  if (value == selected) return;
                  ref.read(hapticServiceProvider).selectionClick();
                  onSelected(value);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.semanticLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
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
