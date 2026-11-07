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
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/spy/spy_game_state.dart';
import '../viewmodels/spy_game_notifier.dart';
import '../viewmodels/spy_timer_notifier.dart';
import '../widgets/spy_dialogs.dart';
import '../widgets/spy_locations_sheet.dart';
import '../widgets/spy_missing_game_view.dart';

const double _progressHeight = 8;
const double _pulseScale = 1.08;
const double _askerAvatarSize = 48;

/// Soru-cevap turu ekranı.
///
/// - Üstte gerilim katan tur sayacı: son 30 saniyede kırmızıya döner ve her
///   saniye nabız atar; süre bitince oylamaya çağırır.
/// - "İlk Soruyu Ayşe Soruyor!" kartı.
/// - Altta iki aksiyon: "Ajanım, Konumu Tahmin Edeceğim!" (kilitli onaylı)
///   ve "Ajanı Oyla".
class SpyGameScreen extends ConsumerWidget {
  const SpyGameScreen({super.key});

  Future<void> _requestExit(BuildContext context, WidgetRef ref) async {
    final approved = await confirmSpyExit(context);
    if (!approved || !context.mounted) return;
    ref.read(spyTimerProvider.notifier).stop();
    ref.read(spyGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  Future<void> _spyGuess(BuildContext context, WidgetRef ref) async {
    final approved = await confirmSpyGuess(context);
    if (!approved || !context.mounted) return;
    ref.read(spyTimerProvider.notifier).stop();
    ref.read(spyGameProvider.notifier).startSpyGuess();
    context.go(AppRouter.spyGuess);
  }

  Future<void> _startVoting(BuildContext context, WidgetRef ref) async {
    final approved = await confirmSpyVoting(context);
    if (!approved || !context.mounted) return;
    ref.read(spyTimerProvider.notifier).stop();
    ref.read(spyGameProvider.notifier).startVoting();
    context.go(AppRouter.spyVote);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(spyGameProvider);
    if (game == null) return const SpyMissingGameView();

    final isPlaying = game.phase == SpyPhase.inProgress;

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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _requestExit(context, ref),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: 'Oyundan çık',
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => showSpyLocationsSheet(
                            context,
                            locations: game.allLocations,
                          ),
                          icon: const Icon(
                            Icons.map,
                            color: AppColors.secondary,
                          ),
                          label: Text(
                            'Konumlar',
                            style: AppTypography.label.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    const _TimerCard(),
                    const SizedBox(height: AppSpacing.m),
                    _FirstAskerCard(game: game),
                    const SizedBox(height: AppSpacing.m),
                    const _TipsCard(),
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
                      label: 'Ajanım, Konumu Tahmin Edeceğim!',
                      variant: ButtonVariant.danger,
                      fullWidth: true,
                      onPressed:
                          isPlaying ? () => _spyGuess(context, ref) : null,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    AppButton(
                      label: 'Ajanı Oyla',
                      variant: ButtonVariant.secondary,
                      fullWidth: true,
                      onPressed:
                          isPlaying ? () => _startVoting(context, ref) : null,
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

class _TimerCard extends ConsumerWidget {
  const _TimerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(spyTimerProvider);
    final color = timer.isFinished
        ? AppColors.warning
        : timer.isFinalCountdown
            ? AppColors.error
            : AppColors.primary;
    final seconds = timer.remainingSeconds;
    final text = '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';

    return AnimatedContainer(
      duration: AppMotion.slow,
      curve: AppMotion.standardCurve,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppShadows.glow(color, timer.isFinalCountdown ? 0.5 : 0.25),
            blurRadius: timer.isFinalCountdown ? 28 : 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            timer.isFinished ? 'SÜRE DOLDU!' : 'KALAN SÜRE',
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.s),
          Semantics(
            label: timer.isFinished
                ? 'Süre doldu'
                : 'Kalan süre: ${seconds ~/ 60} dakika ${seconds % 60} saniye',
            liveRegion: timer.isFinalCountdown,
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedScale(
                // Son 30 saniyede her saniye kısa bir "vuruş".
                scale:
                    timer.isFinalCountdown && seconds.isOdd ? _pulseScale : 1,
                duration: AppMotion.fast,
                curve: AppMotion.standardCurve,
                child: Text(
                  timer.isFinished ? '00:00' : text,
                  style: AppTypography.timerDisplay.copyWith(
                    color: color,
                    shadows: [
                      Shadow(
                        color: AppShadows.glow(color, 0.5),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: timer.isFinished ? 0 : timer.progress),
              duration: const Duration(seconds: 1),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: _progressHeight,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (timer.isFinished) ...[
            const SizedBox(height: AppSpacing.m),
            const Text(
              'Sorular bitti! Ajanı bulmak için oylamaya geçin. Ajan hâlâ '
              'konumu tahmin etmeyi deneyebilir.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _FirstAskerCard extends StatelessWidget {
  const _FirstAskerCard({required this.game});

  final SpyGameState game;

  @override
  Widget build(BuildContext context) {
    final asker = game.firstAsker;
    return AppCard(
      variant: CardVariant.highlighted,
      child: Row(
        children: [
          PlayerAvatar(
            name: asker.name,
            size: _askerAvatarSize,
            state: AvatarState.selected,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İlk Soruyu ${asker.name} Soruyor!',
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Bir oyuncu seçip konumla ilgili bir soru sor. Cevap veren '
                  'sıradaki soruyu sorar.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İpuçları', style: AppTypography.title),
          SizedBox(height: AppSpacing.s),
          Text(
            '• Masumlar: Soruların çok açık olmasın, ajan konumu çözer.\n'
            '• Ajan: Genel cevaplar ver, kimseyi şüphelendirme.\n'
            '• Sana soru soran kişiye hemen geri soru soramazsın.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
