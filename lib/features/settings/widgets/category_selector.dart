import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../utils/settings_labels.dart';

const int _columnCount = 2;
const double _checkIconSize = 20;

/// Kategori seçici: "Karışık" + tüm kategoriler, 2 sütunlu kart ızgarası.
///
/// Seçili kart lime çerçeve + glow'a ek olarak onay ikonu da gösterir.
/// `onSelected(null)` "Karışık" anlamına gelir.
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categoryIds,
    required this.selectedCategoryId,
    required this.onSelected,
    this.labelOf = categoryLabel,
  });

  final List<String> categoryIds;

  /// Kategori id'sini ekrandaki ada çevirir (`null` = Karışık). Varsayılan:
  /// Imposter'ın id = ad düzeni ([categoryLabel]).
  final String Function(String? categoryId) labelOf;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    // null = Karışık, her zaman ilk sırada.
    final options = <String?>[null, ...categoryIds];

    return LayoutBuilder(
      builder: (context, constraints) {
        const totalGap = AppSpacing.s * (_columnCount - 1);
        final itemWidth = (constraints.maxWidth - totalGap) / _columnCount;

        return Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final id in options)
              SizedBox(
                width: itemWidth,
                child: _CategoryCard(
                  label: labelOf(id),
                  isSelected: id == selectedCategoryId,
                  onTap: () => onSelected(id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
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
      label: '$label kategorisi',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
          variant: isSelected ? CardVariant.highlighted : CardVariant.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.m,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: _checkIconSize,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
