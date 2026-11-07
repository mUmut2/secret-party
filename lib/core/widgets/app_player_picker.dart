import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_shadows.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'player_avatar.dart';

const double _avatarSize = 36;
const double _checkIconSize = 22;
const double _borderWidth = 1.5;

/// Seçicide gösterilecek bir oyuncu (oyundan bağımsız).
class AppPickerEntry {
  const AppPickerEntry({required this.id, required this.name});

  final String id;
  final String name;
}

/// Listeden TEK oyuncu seçmek için ortak bileşen (oylama, hedef seçimi vb.).
///
/// Seçili oyuncu renge ek olarak onay ikonu ve "Seçildi" yazısıyla belirtilir
/// (renk tek başına anlam taşımaz). Her seçim değişikliğinde hafif bir
/// `selectionClick` titreşimi verir.
class AppPlayerPicker extends ConsumerWidget {
  const AppPlayerPicker({
    super.key,
    required this.entries,
    required this.selectedId,
    required this.onSelected,
    this.accentColor = AppColors.primary,
    this.surfaceColor = AppColors.surface,
    this.semanticAction = 'seç',
  });

  final List<AppPickerEntry> entries;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final Color accentColor;
  final Color surfaceColor;

  /// Ekran okuyucu fiili, örn. "oy ver".
  final String semanticAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries) ...[
          _PickerTile(
            entry: entry,
            isSelected: entry.id == selectedId,
            accentColor: accentColor,
            surfaceColor: surfaceColor,
            semanticAction: semanticAction,
            onTap: () {
              if (entry.id == selectedId) return;
              ref.read(hapticServiceProvider).selectionClick();
              onSelected(entry.id);
            },
          ),
          const SizedBox(height: AppSpacing.s),
        ],
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.entry,
    required this.isSelected,
    required this.accentColor,
    required this.surfaceColor,
    required this.semanticAction,
    required this.onTap,
  });

  final AppPickerEntry entry;
  final bool isSelected;
  final Color accentColor;
  final Color surfaceColor;
  final String semanticAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${entry.name}, $semanticAction',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: isSelected ? accentColor : AppColors.transparent,
              width: _borderWidth,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppShadows.glow(accentColor, 0.3),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              PlayerAvatar(name: entry.name, size: _avatarSize),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge,
                ),
              ),
              if (isSelected) ...[
                Icon(
                  Icons.check_circle,
                  color: accentColor,
                  size: _checkIconSize,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Seçildi',
                  style: AppTypography.label.copyWith(color: accentColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
