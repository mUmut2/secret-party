import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/models/werewolf/werewolf_game_state.dart';
import '../viewmodels/werewolf_day_timer_notifier.dart';
import '../viewmodels/werewolf_game_notifier.dart';
import '../widgets/werewolf_death_card.dart';
import '../widgets/werewolf_dialogs.dart';
import '../widgets/werewolf_hunter_decision.dart';
import '../widgets/werewolf_missing_game_view.dart';

const double _sunIconSize = 64;
const double _progressHeight = 6;
const double _pulseScale = 1.1;

/// "Güneş Doğdu" ekranı.
///
/// 1. Gece yaşananları duyurur (kim öldü / kimse ölmedi).
/// 2. Gece ölen avcı varsa "Avcı Elendi!" kararını aldırır.
/// 3. Oyun bitmediyse tartışma sayacını başlatır ve bireysel gizli
///    oylamaya geçirir.
///
/// Gündüz teması: lime ve kehribar vurgular.
class WerewolfDayScreen extends ConsumerWidget {
  const WerewolfDayScreen({super.key});

  Future<void> _requestExit(BuildContext context, WidgetRef ref) async {
    final approved = await confirmWerewolfExit(context);
    if (!approved || !context.mounted) return;
    ref.read(werewolfGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  void _goToVoting(BuildContext context, WidgetRef ref) {
    ref.read(werewolfDayTimerProvider.notifier).stop();
    ref.read(werewolfGameProvider.notifier).startVoting();
    context.go(AppRouter.werewolfVoting);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(werewolfGameProvider);
    if (game == null) return const WerewolfMissingGameView();

    final showDiscussion = !game.isFinished && !game.hasPendingHunterDecision;
    // Gündüz fazında yapılmış tek avcı atışı, geceki ölümden doğandır.
    final hunterVictim = game.deaths
        .where(
          (d) =>
              d.cause == WerewolfDeathCause.hunter &&
              d.dayNumber == game.dayNumber,
        )
        .firstOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit(context, ref);
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => _requestExit(context, ref),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'Oyundan çık',
                      ),
                    ),
                    _SunriseHeader(dayNumber: game.dayNumber),
                    const SizedBox(height: AppSpacing.l),
                    _NightReport(game: game),
                    if (game.hasPendingHunterDecision) ...[
                      const SizedBox(height: AppSpacing.l),
                      WerewolfHunterDecision(game: game),
                    ],
                    if (hunterVictim != null) ...[
                      const SizedBox(height: AppSpacing.m),
                      WerewolfDeathCard(
                        player: game.playerById(hunterVictim.playerId),
                        message: hunterVictim.cause.label,
                        revealRole: game.settings.revealRoleOnDeath,
                      ),
                    ],
                    if (showDiscussion) ...[
                      const SizedBox(height: AppSpacing.l),
                      _DiscussionCard(
                        game: game,
                        seconds: game.settings.discussionSeconds,
                      ),
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
                child: game.isFinished
                    ? AppButton(
                        label: 'Sonuçları Gör',
                        variant: ButtonVariant.primary,
                        fullWidth: true,
                        onPressed: () => context.go(AppRouter.werewolfResult),
                      )
                    : AppButton(
                        label: 'Bireysel Oylamayı Başlat',
                        variant: ButtonVariant.primary,
                        fullWidth: true,
                        onPressed: game.hasPendingHunterDecision
                            ? null
                            : () => _goToVoting(context, ref),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunriseHeader extends StatelessWidget {
  const _SunriseHeader({required this.dayNumber});

  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.dramatic,
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Transform.translate(
            offset: Offset(0, (1 - t) * AppSpacing.xl),
            child: Opacity(opacity: t.clamp(0, 1), child: child),
          ),
          child: const Icon(
            Icons.wb_sunny,
            size: _sunIconSize,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          'Güneş Doğdu',
          textAlign: TextAlign.center,
          style: AppTypography.display.copyWith(
            shadows: [
              Shadow(
                color: AppShadows.glow(AppColors.warning, 0.5),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$dayNumber. GÜN',
          style: AppTypography.label.copyWith(color: AppColors.warning),
        ),
      ],
    );
  }
}

/// Gecenin bilançosu.
class _NightReport extends StatelessWidget {
  const _NightReport({required this.game});

  final WerewolfGameState game;

  @override
  Widget build(BuildContext context) {
    if (game.lastNightDeaths.isEmpty) {
      return AppCard(
        variant: CardVariant.highlighted,
        child: Column(
          children: [
            const Text(
              'Bu gece kimse ölmedi!',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              game.someoneSavedLastNight
                  ? 'Biri ölümün eşiğinden döndü... Ama kim kurtardı?'
                  : 'Köy derin bir nefes aldı.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      );
    }

    final plural = game.lastNightDeaths.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          plural
              ? 'Bu gece ${game.lastNightDeaths.length} kişi hayatını kaybetti.'
              : 'Bu gece köy bir kişiyi kaybetti.',
          textAlign: TextAlign.center,
          style: AppTypography.title,
        ),
        const SizedBox(height: AppSpacing.m),
        for (final id in game.lastNightDeaths) ...[
          WerewolfDeathCard(
            player: game.playerById(id),
            message: 'Sabah cansız bulundu.',
            revealRole: game.settings.revealRoleOnDeath,
          ),
          const SizedBox(height: AppSpacing.s),
        ],
      ],
    );
  }
}

/// Tartışma sayacı kartı.
class _DiscussionCard extends ConsumerWidget {
  const _DiscussionCard({required this.game, required this.seconds});

  final WerewolfGameState game;
  final int seconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(werewolfDayTimerProvider);
    final remaining =
        timer.status == DayTimerStatus.idle ? seconds : timer.remainingSeconds;
    final color = timer.isFinalCountdown
        ? AppColors.error
        : timer.isFinished
            ? AppColors.warning
            : AppColors.primary;
    final text = '${(remaining ~/ 60).toString().padLeft(2, '0')}:'
        '${(remaining % 60).toString().padLeft(2, '0')}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Köy Meydanı', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Hayatta ${game.alivePlayers.length} kişi kaldı. Şüphelerinizi '
            'tartışın. Ardından telefon sırayla herkese verilecek ve '
            'herkes gizlice oyunu kullanacak.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.m),
          Semantics(
            label: 'Kalan tartışma süresi: $remaining saniye',
            liveRegion: timer.isFinalCountdown,
            excludeSemantics: true,
            child: Center(
              child: AnimatedScale(
                scale:
                    timer.isFinalCountdown && remaining.isOdd ? _pulseScale : 1,
                duration: AppMotion.fast,
                child: Text(
                  timer.isFinished ? 'SÜRE BİTTİ!' : text,
                  style: (timer.isFinished
                          ? AppTypography.headline
                          : AppTypography.timerDisplay)
                      .copyWith(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  end:
                      timer.status == DayTimerStatus.idle ? 1 : timer.progress),
              duration: const Duration(seconds: 1),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: _progressHeight,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (timer.status == DayTimerStatus.idle) ...[
            const SizedBox(height: AppSpacing.m),
            AppButton(
              label: 'Tartışmayı Başlat',
              variant: ButtonVariant.outlined,
              fullWidth: true,
              onPressed: () =>
                  ref.read(werewolfDayTimerProvider.notifier).start(seconds),
            ),
          ],
        ],
      ),
    );
  }
}
