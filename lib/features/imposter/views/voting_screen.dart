import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/player.dart';
import '../../../domain/services/game_engine_notifier.dart';
import '../viewmodels/voting_notifier.dart';
import '../widgets/imposter_exit.dart';

const double _selectedCardScale = 1.02;
const double _checkIconSize = 24;
const double _avatarSize = 40;
const double _dialogAvatarSize = 64;

/// Oylama ekranı: grup tartışır, telefonu tutan kişi ortak kararı işaretler.
///
/// Seçili durum renge ek olarak onay ikonu ve "Seçildi" yazısıyla da
/// belirtilir (renk tek başına anlam taşımaz). Onaylanınca karar oyun
/// motoruna iletilir, sonuç hesaplanır ve sonuç ekranına geçilir.
class VotingScreen extends ConsumerWidget {
  const VotingScreen({super.key});

  /// Eleme geri alınamaz; bu yüzden önce grup kararı bir kez daha onaylanır.
  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    Player suspect,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (_) => _ConfirmEliminationDialog(suspect: suspect),
    );
    if (approved != true || !context.mounted) return;

    final recorded = ref.read(votingProvider.notifier).confirmVote();
    if (recorded) {
      context.go(AppRouter.result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    final voting = ref.watch(votingProvider);
    final suspect = session?.players
        .where((p) => p.id == voting.selectedPlayerId)
        .firstOrNull;

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Aktif bir oyun oturumu bulunamadı.',
            style: AppTypography.bodyLarge,
          ),
        ),
      );
    }

    // Geri tuşuyla oylamadan yanlışlıkla çıkılmasını engeller.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) requestImposterExit(context, ref);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Şüpheliyi Seçin', style: AppTypography.display),
                const SizedBox(height: AppSpacing.s),
                const Text(
                  'Grupça tartışın ve ortak kararınızı işaretleyin.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.l),
                Expanded(
                  child: ListView.separated(
                    itemCount: session.players.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) {
                      final player = session.players[index];
                      return _SuspectCard(
                        player: player,
                        isSelected: player.id == voting.selectedPlayerId,
                        onTap: () => ref
                            .read(votingProvider.notifier)
                            .selectPlayer(player.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                AppButton(
                  label: 'Kararı Onayla ve Yüzleş',
                  variant: ButtonVariant.primary,
                  fullWidth: true,
                  // Oyuncu seçilmediyse null → buton pasif.
                  onPressed: suspect == null
                      ? null
                      : () => _confirm(context, ref, suspect),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuspectCard extends StatelessWidget {
  const _SuspectCard({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  final Player player;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${player.name}, şüpheli olarak seç',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? _selectedCardScale : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          child: AppCard(
            variant:
                isSelected ? CardVariant.highlighted : CardVariant.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Row(
              children: [
                PlayerAvatar(
                  name: player.name,
                  size: _avatarSize,
                  state:
                      isSelected ? AvatarState.selected : AvatarState.default_,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    player.name,
                    style: AppTypography.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: _checkIconSize,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Seçildi',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Emin misiniz?" diyaloğu. Onaylanırsa `true`, vazgeçilirse `false` döner.
class _ConfirmEliminationDialog extends StatelessWidget {
  const _ConfirmEliminationDialog({required this.suspect});

  final Player suspect;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PlayerAvatar(
                name: suspect.name,
                size: _dialogAvatarSize,
                state: AvatarState.selected,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              '${suspect.name} elensin mi?',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Bu karar geri alınamaz. Kimin Imposter olduğu hemen açıklanacak.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: 'Evet, Ele',
              variant: ButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.s),
            AppButton(
              label: 'Vazgeç',
              variant: ButtonVariant.ghost,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
