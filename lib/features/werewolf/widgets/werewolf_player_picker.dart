import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/werewolf/werewolf_player.dart';

const double _avatarSize = 36;
const double _checkIconSize = 22;
const double _borderWidth = 1.5;

/// Vampir Köylü ekranlarında tek kişi seçmek için kullanılan liste
/// (vampir hedefi, doktor koruması, zehir, avcı atışı, sürgün oylaması).
///
/// Gece ve gündüz temasına uyum için vurgu ve zemin rengi dışarıdan verilir.
/// Seçili oyuncu renge ek olarak onay ikonu ve "Seçildi" yazısıyla belirtilir.
class WerewolfPlayerPicker extends ConsumerWidget {
  const WerewolfPlayerPicker({
    super.key,
    required this.players,
    required this.selectedId,
    required this.onSelected,
    this.accentColor = AppColors.primary,
    this.surfaceColor = AppColors.surface,
    this.noneOptionLabel,
    this.semanticAction = 'seç',
  });

  final List<WerewolfPlayer> players;

  /// Seçili oyuncu. [noneOptionLabel] verildiyse `null` = "kimse" seçeneği.
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final Color accentColor;
  final Color surfaceColor;

  /// Verilirse listenin sonuna "kimseyi seçme" seçeneği eklenir.
  final String? noneOptionLabel;

  /// Ekran okuyucu fiili, örn. "koru", "sürgün et".
  final String semanticAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void select(String? id) {
      if (id == selectedId) return;
      ref.read(hapticServiceProvider).selectionClick();
      onSelected(id);
    }

    final noneLabel = noneOptionLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final player in players) ...[
          _PickerTile(
            label: player.name,
            leading: PlayerAvatar(name: player.name, size: _avatarSize),
            isSelected: player.id == selectedId,
            accentColor: accentColor,
            surfaceColor: surfaceColor,
            semanticLabel: '${player.name}, $semanticAction',
            onTap: () => select(player.id),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        if (noneLabel != null)
          _PickerTile(
            label: noneLabel,
            leading: const SizedBox.square(
              dimension: _avatarSize,
              child: Icon(Icons.block, color: AppColors.textSecondary),
            ),
            isSelected: selectedId == null,
            accentColor: accentColor,
            surfaceColor: surfaceColor,
            semanticLabel: noneLabel,
            onTap: () => select(null),
          ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.leading,
    required this.isSelected,
    required this.accentColor,
    required this.surfaceColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final bool isSelected;
  final Color accentColor;
  final Color surfaceColor;
  final String semanticLabel;
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
              leading,
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge,
                ),
              ),
              if (isSelected) ...[
                Icon(Icons.check_circle,
                    color: accentColor, size: _checkIconSize),
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
