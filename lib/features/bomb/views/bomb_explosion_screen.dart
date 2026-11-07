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
import '../../../domain/models/bomb/bomb_game_state.dart';
import '../viewmodels/bomb_game_notifier.dart';
import '../widgets/bomb_exit.dart';
import '../widgets/bomb_missing_game_view.dart';

const double _blastIconSize = 96;
const double _entryScaleStart = 0.6;

/// Patlama anı: "PATLADI!", patlayan oyuncu ve oyundaki patlama sayısı.
class BombExplosionScreen extends ConsumerWidget {
  const BombExplosionScreen({super.key});

  void _continue(BuildContext context, WidgetRef ref) {
    ref.read(bombGameProvider.notifier).nextRound();
    final next = ref.read(bombGameProvider);
    if (next == null) return;
    context.go(next.isFinished ? AppRouter.bombFinal : AppRouter.bombReady);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(bombGameProvider);
    final exploded = game?.lastExploded;
    if (game == null || exploded == null) return const BombMissingGameView();

    final count = game.explosionsOf(exploded.id);
    final canContinue = game.phase == BombPhase.exploded;

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
                        Text(
                          'TUR ${game.roundNumber} / ${game.totalRounds}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: _entryScaleStart, end: 1),
                      duration: AppMotion.resolve(context, AppMotion.dramatic),
                      curve: AppMotion.dramaticCurve,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: _blastIconSize,
                            color: AppColors.error,
                          ),
                          SizedBox(height: AppSpacing.s),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'PATLADI!',
                              textAlign: TextAlign.center,
                              style: AppTypography.gameDisplay,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    AppCard(
                      variant: CardVariant.danger,
                      child: Column(
                        children: [
                          Text(
                            exploded.name,
                            textAlign: TextAlign.center,
                            style: AppTypography.headline,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Bomba elindeyken patladı!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'Bu oyunda $count. patlaması',
                            textAlign: TextAlign.center,
                            style: AppTypography.title.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      game.isLastRound
                          ? 'Son tur buydu. Bakalım kim kaç kez patladı?'
                          : 'Sonraki turu ${exploded.name} başlatacak.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
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
                  label: game.isLastRound ? 'Sonuçları Gör' : 'Sonraki Tur',
                  variant: ButtonVariant.warning,
                  fullWidth: true,
                  onPressed: canContinue ? () => _continue(context, ref) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
