import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/bomb/bomb_game_state.dart';
import '../../../domain/models/player.dart';
import '../viewmodels/bomb_game_notifier.dart';
import '../widgets/bomb_exit.dart';
import '../widgets/bomb_graphic.dart';
import '../widgets/bomb_missing_game_view.dart';

const double _bombSize = 96;
const double _avatarSize = 40;
const double _labelIconSize = 22;
const double _entryScaleStart = 0.85;

/// Oyun sonu: patlama sıralaması ve eğlenceli etiketler.
class BombFinalScreen extends ConsumerWidget {
  const BombFinalScreen({super.key});

  void _playAgain(BuildContext context, WidgetRef ref) {
    ref.read(bombGameProvider.notifier).restart();
    context.go(AppRouter.bombReady);
  }

  void _goHome(BuildContext context, WidgetRef ref) {
    ref.read(bombGameProvider.notifier).quit();
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(bombGameProvider);
    if (game == null) return const BombMissingGameView();
    final summary = ref.read(bombGameEngineProvider).summarize(game);

    return BombExitScope(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: _entryScaleStart, end: 1),
                      duration: AppMotion.resolve(context, AppMotion.dramatic),
                      curve: AppMotion.dramaticCurve,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: const Column(
                        children: [
                          BombGraphic(size: _bombSize, lit: false),
                          SizedBox(height: AppSpacing.s),
                          Text(
                            'Oyun Bitti!',
                            textAlign: TextAlign.center,
                            style: AppTypography.display,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    ..._labels(summary),
                    const SizedBox(height: AppSpacing.l),
                    const Text('Patlama Tablosu', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.s),
                    for (var i = 0; i < summary.standings.length; i++) ...[
                      _StandingRow(
                        rank: i + 1,
                        player: summary.standings[i].player,
                        explosions: summary.standings[i].explosions,
                      ),
                      const SizedBox(height: AppSpacing.s),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.s,
                  AppSpacing.l,
                  AppSpacing.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: 'Tekrar Oyna',
                      variant: ButtonVariant.warning,
                      fullWidth: true,
                      onPressed: () => _playAgain(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    AppButton(
                      label: 'Ana Menü',
                      variant: ButtonVariant.ghost,
                      fullWidth: true,
                      onPressed: () => _goHome(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _labels(BombSummary summary) {
    String names(List<Player> players) => players.map((p) => p.name).join(', ');
    final most = summary.mostExploded;
    final last = summary.lastExploded;
    final never = summary.neverExploded;
    return [
      if (most.isNotEmpty)
        _LabelCard(
          icon: Icons.local_fire_department,
          color: AppColors.error,
          title: most.length == 1 ? 'Bomba Mıknatısı' : 'Bomba Mıknatısları',
          value: '${names(most)} · en çok patlayan',
        ),
      if (last != null)
        _LabelCard(
          icon: Icons.timer_off,
          color: AppColors.warning,
          title: 'Son Patlayan',
          value: last.name,
        ),
      _LabelCard(
        icon: Icons.shield,
        color: AppColors.success,
        title: never.isEmpty ? 'Sağ Kalan Yok' : 'Hiç Patlamayan',
        value: never.isEmpty ? 'Herkes en az bir kez patladı!' : names(never),
      ),
    ];
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, size: _labelIconSize, color: color),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperTr(),
                    style: AppTypography.caption.copyWith(color: color),
                  ),
                  Text(value, style: AppTypography.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rank,
    required this.player,
    required this.explosions,
  });

  final int rank;
  final Player player;
  final int explosions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rank. ${player.name}, $explosions patlama',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            Text('$rank.', style: AppTypography.title),
            const SizedBox(width: AppSpacing.s),
            PlayerAvatar(name: player.name, size: _avatarSize),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            const Icon(
              Icons.local_fire_department,
              size: _labelIconSize,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('$explosions', style: AppTypography.title),
          ],
        ),
      ),
    );
  }
}
