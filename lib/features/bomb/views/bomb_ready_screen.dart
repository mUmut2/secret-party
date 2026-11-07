import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/models/bomb/bomb_game_state.dart';
import '../viewmodels/bomb_game_notifier.dart';
import '../widgets/bomb_exit.dart';
import '../widgets/bomb_graphic.dart';
import '../widgets/bomb_missing_game_view.dart';

const double _bombSize = 140;

/// "Hazır mısınız?" ekranı: her turdan önce bombayı ilk kimin alacağını
/// gösterir. Görev, fitil ateşlenince bomba ekranında açılır.
class BombReadyScreen extends ConsumerWidget {
  const BombReadyScreen({super.key});

  void _start(BuildContext context, WidgetRef ref) {
    ref.read(bombGameProvider.notifier).startRound();
    context.go(AppRouter.bombPlay);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(bombGameProvider);
    if (game == null) return const BombMissingGameView();

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
                    Row(
                      children: [
                        const BombExitButton(),
                        const Spacer(),
                        _RoundBadge(game: game),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Center(
                      child: BombGraphic(size: _bombSize, lit: false),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Text(
                      'Hazır mısınız?',
                      textAlign: TextAlign.center,
                      style: AppTypography.display,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    AppCard(
                      child: Column(
                        children: [
                          const Text(
                            'Bombayı ilk alan',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            game.holder.name,
                            textAlign: TextAlign.center,
                            style: AppTypography.headline.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          const Text(
                            'Görev, fitil ateşlenince görünecek. Telefonu '
                            'eline al ve hazırlan!',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
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
                child: AppButton(
                  label: 'Fitili Ateşle',
                  variant: ButtonVariant.warning,
                  fullWidth: true,
                  onPressed: game.phase == BombPhase.ready
                      ? () => _start(context, ref)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "TUR 3 / 10" rozeti.
class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.game});

  final BombGameState game;

  @override
  Widget build(BuildContext context) {
    return Text(
      'TUR ${game.roundNumber} / ${game.totalRounds}',
      style: AppTypography.label.copyWith(color: AppColors.warning),
    );
  }
}
