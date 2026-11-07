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
import '../../../domain/models/werewolf/werewolf_game_state.dart';
import '../../../domain/models/werewolf/werewolf_player.dart';
import '../../../domain/models/werewolf/werewolf_role.dart';
import '../viewmodels/werewolf_game_notifier.dart';
import '../widgets/werewolf_role_style.dart';

const double _verdictIconSize = 64;
const double _roleIconSize = 24;
const double _entryScaleStart = 0.7;

/// Zafer ekranı: kazanan tarafı ilan eder ve herkesin gerçek rolünü açar.
///
/// Gösterdiği bitmiş oyunu kendi içinde saklar; "Yeniden Oyna" yeni oyunu
/// hemen başlattığında geçiş animasyonu boyunca içerik değişmez.
class WerewolfResultScreen extends ConsumerStatefulWidget {
  const WerewolfResultScreen({super.key});

  @override
  ConsumerState<WerewolfResultScreen> createState() =>
      _WerewolfResultScreenState();
}

class _WerewolfResultScreenState extends ConsumerState<WerewolfResultScreen> {
  WerewolfGameState? _snapshot;

  void _playAgain() {
    ref.read(werewolfGameProvider.notifier).restart();
    context.go(AppRouter.werewolfReveal);
  }

  void _goHome() {
    ref.read(werewolfGameProvider.notifier).quit();
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(werewolfGameProvider);
    if (live != null && live.isFinished) _snapshot = live;

    final game = _snapshot;
    if (game == null || game.winner == null) {
      return _MissingResultView(onGoHome: () => context.go(AppRouter.home));
    }

    final winner = game.winner!;
    // Önce kazananlar, sonra kaybedenler; her grup içinde hayatta olanlar önde.
    final players = [...game.players]..sort((a, b) {
        final teamOrder = (a.role.team == winner ? 0 : 1)
            .compareTo(b.role.team == winner ? 0 : 1);
        if (teamOrder != 0) return teamOrder;
        return (a.isAlive ? 0 : 1).compareTo(b.isAlive ? 0 : 1);
      });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: winner == WerewolfTeam.vampires
            ? AppColors.nightBackground
            : AppColors.background,
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
                      child: _WinnerBanner(game: game, winner: winner),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Text('Köyün Gerçek Yüzü', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.s),
                    for (final player in players) ...[
                      _PlayerRoleRow(
                        player: player,
                        death: game.deathOf(player.id),
                        isWinner: player.role.team == winner,
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

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.game, required this.winner});

  final WerewolfGameState game;
  final WerewolfTeam winner;

  @override
  Widget build(BuildContext context) {
    final color = winner.color;
    final isVampires = winner == WerewolfTeam.vampires;

    return Column(
      children: [
        Icon(winner.icon, size: _verdictIconSize, color: color),
        const SizedBox(height: AppSpacing.m),
        Text(
          '${winner.label.toUpperTr()}\nKAZANDI!',
          textAlign: TextAlign.center,
          style: AppTypography.gameDisplay.copyWith(
            color: color,
            shadows: [
              Shadow(color: AppShadows.glow(color, 0.55), blurRadius: 28),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          isVampires
              ? 'Vampirler köyü ele geçirdi. Sokak lambaları bir daha hiç '
                  'yanmadı...'
              : 'Son vampir de yakalandı. Köy nihayet huzur içinde uyuyabilir.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          '${game.dayNumber} gün sürdü · ${game.alivePlayers.length} kişi '
          'hayatta kaldı',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

class _PlayerRoleRow extends StatelessWidget {
  const _PlayerRoleRow({
    required this.player,
    required this.death,
    required this.isWinner,
  });

  final WerewolfPlayer player;
  final WerewolfDeath? death;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final role = player.role;
    final death = this.death;
    final status = death == null
        ? 'Hayatta'
        : '${death.cause.label} · ${death.dayNumber}. gün';

    return Semantics(
      label: '${player.name}, ${role.label}, $status',
      excludeSemantics: true,
      child: AppCard(
        variant: isWinner ? CardVariant.highlighted : CardVariant.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            Icon(role.icon, color: role.color, size: _roleIconSize),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      color: player.isAlive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      decoration:
                          player.isAlive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  Text(status, style: AppTypography.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              role.label.toUpperTr(),
              style: AppTypography.label.copyWith(color: role.color),
            ),
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
                'Gösterilecek bir Vampir Köylü sonucu bulunamadı.',
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
