import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/werewolf/werewolf_player.dart';
import 'werewolf_role_style.dart';

const double _avatarSize = 48;

/// Bir oyuncunun öldüğünü / sürgün edildiğini duyuran kart.
///
/// [revealRole] kapalıysa (oyun ayarı) rol gizli kalır.
class WerewolfDeathCard extends StatelessWidget {
  const WerewolfDeathCard({
    super.key,
    required this.player,
    required this.message,
    required this.revealRole,
  });

  final WerewolfPlayer player;
  final String message;
  final bool revealRole;

  @override
  Widget build(BuildContext context) {
    final role = player.role;
    return AppCard(
      variant: CardVariant.danger,
      child: Row(
        children: [
          PlayerAvatar(name: player.name, size: _avatarSize),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTypography.bodyMedium),
                if (revealRole) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(role.icon, size: AppSpacing.m, color: role.color),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          'Rolü: ${role.label}',
                          style:
                              AppTypography.label.copyWith(color: role.color),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Rolü gizli kaldı.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
