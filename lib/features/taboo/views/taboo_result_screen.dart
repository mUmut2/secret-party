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
import '../../../domain/models/taboo_match.dart';
import '../viewmodels/taboo_game_notifier.dart';
import '../widgets/taboo_exit_dialog.dart';
import '../widgets/taboo_scoreboard.dart';

const double _verdictIconSize = 56;
const double _entryScaleStart = 0.6;
const double _entryIconSize = 20;

/// Tur sonu / oyun sonu ekranı.
///
/// - `roundEnded`: tur özeti + skor tablosu, sırayı diğer takıma devret.
/// - `gameFinished`: kazanan takım ilanı, final skorları, "Yeniden Oyna".
///
/// Ekran, gösterdiği bitmiş durumu kendi içinde saklar: butona basılınca maç
/// hemen `ready` durumuna geçer ve geçiş animasyonu sürerken bu ekranın
/// içeriği değişmemelidir.
class TabooResultScreen extends ConsumerStatefulWidget {
  const TabooResultScreen({super.key});

  @override
  ConsumerState<TabooResultScreen> createState() => _TabooResultScreenState();
}

class _TabooResultScreenState extends ConsumerState<TabooResultScreen> {
  TabooMatch? _snapshot;

  void _passTurn() {
    ref.read(tabooGameProvider.notifier).passTurnToNextTeam();
    context.go(AppRouter.tabooGame);
  }

  void _playAgain() {
    ref.read(tabooGameProvider.notifier).restart();
    context.go(AppRouter.tabooGame);
  }

  void _goHome() {
    ref.read(tabooGameProvider.notifier).quit();
    context.go(AppRouter.home);
  }

  Future<void> _requestExit() async {
    final approved = await confirmTabooExit(context);
    if (!approved || !mounted) return;
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(tabooGameProvider);
    if (live != null &&
        (live.status == TabooGameStatus.roundEnded ||
            live.status == TabooGameStatus.gameFinished)) {
      _snapshot = live;
    }

    final match = _snapshot;
    if (match == null) {
      return _MissingResultView(onGoHome: () => context.go(AppRouter.home));
    }

    final isGameOver = match.status == TabooGameStatus.gameFinished;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isGameOver) {
          _goHome();
        } else {
          _requestExit();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: _entryScaleStart, end: 1),
                      duration: AppMotion.resolve(context, AppMotion.dramatic),
                      curve: AppMotion.dramaticCurve,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: isGameOver
                          ? _GameOverContent(match: match)
                          : _RoundEndContent(match: match),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                if (isGameOver) ...[
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
                ] else ...[
                  AppButton(
                    label: 'Sırayı Devret: ${match.nextTeam.name}',
                    variant: ButtonVariant.primary,
                    fullWidth: true,
                    onPressed: _passTurn,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  AppButton(
                    label: 'Oyunu Bitir',
                    variant: ButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: _requestExit,
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

/// Tur sonu: anlatan takımın tur özeti ve genel skor.
class _RoundEndContent extends StatelessWidget {
  const _RoundEndContent({required this.match});

  final TabooMatch match;

  @override
  Widget build(BuildContext context) {
    final teamColor = tabooTeamColor(match.activeTeamIndex);
    final points = match.turnPoints;
    final pointsText = points > 0 ? '+$points' : '$points';
    final pointsColor = points > 0
        ? AppColors.primary
        : points < 0
            ? AppColors.error
            : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TUR BİTTİ',
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          match.activeTeam.name,
          textAlign: TextAlign.center,
          style: AppTypography.display.copyWith(color: teamColor),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          '$pointsText puan',
          textAlign: TextAlign.center,
          style: AppTypography.gameDisplay.copyWith(color: pointsColor),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          '${match.countOf(TabooOutcome.correct)} doğru · '
          '${match.countOf(TabooOutcome.taboo)} tabu · '
          '${match.countOf(TabooOutcome.pass)} pas',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.l),
        TabooScoreboard(
          match: match,
          highlightIndex: match.nextTeamIndex,
          badgeLabel: 'Sıradaki',
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          _standingText(match),
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
        if (match.turnEntries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          const Text('Bu Turun Kartları', style: AppTypography.title),
          const SizedBox(height: AppSpacing.s),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Column(
              children: [
                for (final entry in match.turnEntries) _EntryRow(entry: entry),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Hedefe ulaşıldı ama tur eşitliği bekleniyorsa bunu açıkça söyler.
  String _standingText(TabooMatch match) {
    final target = match.settings.targetScore;
    final reachedTarget = match.teams.any((t) => t.score >= target);
    if (reachedTarget && match.completedTurns.isOdd) {
      return 'Hedefe ulaşıldı! ${match.nextTeam.name} eşitlemek için son '
          'turunu oynayacak.';
    }
    if (reachedTarget) {
      return 'Skorlar eşit — kazanan çıkana kadar oyun devam ediyor.';
    }
    return 'Hedef: $target puan';
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final TabooTurnEntry entry;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = switch (entry.outcome) {
      TabooOutcome.correct => (Icons.check_circle, AppColors.primary, 'Doğru'),
      TabooOutcome.taboo => (Icons.block, AppColors.error, 'Tabu'),
      TabooOutcome.pass => (Icons.skip_next, AppColors.warning, 'Pas'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: _entryIconSize, color: color),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              entry.card.targetWord,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLarge,
            ),
          ),
          Text(
            label.toUpperTr(),
            style: AppTypography.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Oyun sonu: kazanan takım ilanı ve final skorları.
class _GameOverContent extends StatelessWidget {
  const _GameOverContent({required this.match});

  final TabooMatch match;

  @override
  Widget build(BuildContext context) {
    final winnerIndex = match.winnerIndex ?? match.activeTeamIndex;
    final winner = match.teams[winnerIndex];
    final loser = match.teams[1 - winnerIndex];
    final color = tabooTeamColor(winnerIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.emoji_events,
          size: _verdictIconSize,
          color: color,
          semanticLabel: 'Kupa',
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          winner.name.toUpperTr(),
          textAlign: TextAlign.center,
          style: AppTypography.gameDisplay.copyWith(
            color: color,
            shadows: [
              Shadow(color: AppShadows.glow(color, 0.55), blurRadius: 24),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        const Text(
          'KAZANDI!',
          textAlign: TextAlign.center,
          style: AppTypography.display,
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          '${winner.score} – ${loser.score} · ${match.roundNumber - 1} tur',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        TabooScoreboard(
          match: match,
          highlightIndex: winnerIndex,
          badgeLabel: 'Kazanan',
        ),
      ],
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
                'Gösterilecek bir Tabu sonucu bulunamadı.',
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
