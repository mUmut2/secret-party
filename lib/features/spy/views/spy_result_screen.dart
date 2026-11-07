import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/spy/spy_game_state.dart';
import '../../../domain/models/spy/spy_player.dart';
import '../viewmodels/spy_game_notifier.dart';

const double _verdictIconSize = 64;
const double _avatarSize = 36;
const double _entryScaleStart = 0.7;

/// Zafer ekranı: kazanan taraf, nasıl kazandığı, ajan(lar), gerçek konum ve
/// herkesin rolü.
///
/// Gösterdiği bitmiş oyunu kendi içinde saklar; "Yeniden Oyna" yeni oyunu
/// hemen başlattığında geçiş animasyonu boyunca içerik değişmez.
class SpyResultScreen extends ConsumerStatefulWidget {
  const SpyResultScreen({super.key});

  @override
  ConsumerState<SpyResultScreen> createState() => _SpyResultScreenState();
}

class _SpyResultScreenState extends ConsumerState<SpyResultScreen> {
  SpyGameState? _snapshot;

  void _playAgain() {
    ref.read(spyGameProvider.notifier).restart();
    context.go(AppRouter.spyReveal);
  }

  void _goHome() {
    ref.read(spyGameProvider.notifier).quit();
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(spyGameProvider);
    if (live != null && live.isFinished) _snapshot = live;

    final game = _snapshot;
    final outcome = game?.outcome;
    if (game == null || outcome == null) {
      return _MissingResultView(onGoHome: () => context.go(AppRouter.home));
    }

    final spyWon = outcome.winner == SpyTeam.spies;
    final color = spyWon ? AppColors.secondary : AppColors.primary;
    final spyNames = game.spies.map((p) => p.name).join(' ve ');
    final guessed = game.guessedLocationName;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
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
                      child: Column(
                        children: [
                          Icon(
                            spyWon ? Icons.policy : Icons.verified_user,
                            size: _verdictIconSize,
                            color: color,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            spyWon
                                ? '${game.spies.length > 1 ? 'AJANLAR' : 'AJAN'}'
                                    '\nKAZANDI!'
                                : 'MASUMLAR\nKAZANDI!',
                            textAlign: TextAlign.center,
                            style: AppTypography.gameDisplay.copyWith(
                              color: color,
                              shadows: [
                                Shadow(
                                  color: AppShadows.glow(color, 0.55),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            outcome.description,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppCard(
                      variant: CardVariant.highlighted,
                      child: Column(
                        children: [
                          Text(
                            'GERÇEK KONUM',
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            game.location.name.toUpperTr(),
                            textAlign: TextAlign.center,
                            style: AppTypography.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          if (guessed != null) ...[
                            const SizedBox(height: AppSpacing.s),
                            _GuessLine(
                              guessed: guessed,
                              correct: guessed == game.location.name,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppCard(
                      variant: CardVariant.danger,
                      child: Column(
                        children: [
                          Text(
                            game.spies.length > 1 ? 'AJANLAR' : 'AJAN',
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            spyNames,
                            textAlign: TextAlign.center,
                            style: AppTypography.headline.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Text('Herkesin Rolü', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.s),
                    for (final player in game.players) ...[
                      _PlayerRoleRow(
                        player: player,
                        votes: game.voteTally[player.id] ?? 0,
                        showVotes: game.hasVoted,
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
                      label: 'Yeniden Oyna',
                      variant: ButtonVariant.primary,
                      fullWidth: true,
                      onPressed: _playAgain,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    AppButton(
                      label: 'Ana Menüye Dön',
                      variant: ButtonVariant.outlined,
                      fullWidth: true,
                      onPressed: _goHome,
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
}

class _GuessLine extends StatelessWidget {
  const _GuessLine({required this.guessed, required this.correct});

  final String guessed;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.secondary : AppColors.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          correct ? Icons.check_circle : Icons.cancel,
          size: AppSpacing.m,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'Ajanın tahmini: $guessed',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _PlayerRoleRow extends StatelessWidget {
  const _PlayerRoleRow({
    required this.player,
    required this.votes,
    required this.showVotes,
  });

  final SpyPlayer player;
  final int votes;
  final bool showVotes;

  @override
  Widget build(BuildContext context) {
    final role = player.isSpy ? 'AJAN' : (player.roleName ?? '');
    final roleColor = player.isSpy ? AppColors.secondary : AppColors.tertiary;
    return Semantics(
      label: '${player.name}, $role${showVotes ? ', $votes oy' : ''}',
      excludeSemantics: true,
      child: AppCard(
        variant: player.isSpy ? CardVariant.danger : CardVariant.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            PlayerAvatar(
              name: player.name,
              size: _avatarSize,
              state: player.isSpy ? AvatarState.imposter : AvatarState.default_,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge,
                  ),
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: roleColor),
                  ),
                ],
              ),
            ),
            if (showVotes) Text('$votes oy', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _MissingResultView extends StatelessWidget {
  const _MissingResultView({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Gösterilecek bir Ajan sonucu bulunamadı.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Ana Menüye Dön',
                variant: ButtonVariant.outlined,
                fullWidth: true,
                onPressed: onGoHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
