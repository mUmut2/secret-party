import 'dart:async';

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
import '../../../data/repositories/taboo_word_repository.dart';
import '../../../domain/models/taboo_card.dart';
import '../../../domain/models/taboo_match.dart';
import '../viewmodels/taboo_game_notifier.dart';
import '../widgets/taboo_exit_dialog.dart';
import '../widgets/taboo_scoreboard.dart';

/// Süre bittikten sonra sonuç ekranına geçmeden önce "SÜRE BİTTİ!" yazısının
/// görünür kaldığı süre: oyuncular turun bittiğini fark etsin.
const Duration _timeUpHold = Duration(milliseconds: 900);

const double _targetGlowBlur = 24;
const double _targetGlowAlpha = 0.55;
const double _forbiddenGlowAlpha = 0.35;
const double _forbiddenGlowBlur = 10;
const double _cardEntryOffset = 0.08;
const double _cardEntryScale = 0.94;
const double _timerPillMinWidth = 96;
const double _statIconSize = 18;

/// Tur istatistiği satırının gösterilmesi için gereken en az oyun alanı.
const double _statsMinHeight = 440;

/// Tabu oyun ekranı.
///
/// - `ready`: anlatıcı telefonu alır, "Başla" ile süre başlar.
/// - `inProgress`: üstte süre / takım / skor, ortada kart, altta
///   TABU! · PAS · DOĞRU butonları.
/// - `roundEnded` / `gameFinished`: kısa bir "SÜRE BİTTİ!" anından sonra
///   sonuç ekranına geçilir.
class TabooGameScreen extends ConsumerStatefulWidget {
  const TabooGameScreen({super.key});

  @override
  ConsumerState<TabooGameScreen> createState() => _TabooGameScreenState();
}

class _TabooGameScreenState extends ConsumerState<TabooGameScreen> {
  Timer? _navigationTimer;

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _onMatchChanged(TabooMatch? previous, TabooMatch? next) {
    final wasPlaying = previous?.status == TabooGameStatus.inProgress;
    final isOver = next?.status == TabooGameStatus.roundEnded ||
        next?.status == TabooGameStatus.gameFinished;
    if (!wasPlaying || !isOver) return;

    _navigationTimer?.cancel();
    _navigationTimer = Timer(_timeUpHold, () {
      if (mounted) context.go(AppRouter.tabooResult);
    });
  }

  Future<void> _requestExit() async {
    final approved = await confirmTabooExit(context);
    if (!approved || !mounted) return;
    ref.read(tabooGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TabooMatch?>(tabooGameProvider, _onMatchChanged);
    final match = ref.watch(tabooGameProvider);

    if (match == null) {
      return _MissingMatchView(
        onBack: () => context.go(AppRouter.tabooSetup),
      );
    }

    final Widget body;
    switch (match.status) {
      case TabooGameStatus.ready:
        body = _ReadyView(
          key: const ValueKey('ready'),
          match: match,
          onStart: () => ref.read(tabooGameProvider.notifier).startTurn(),
        );
      case TabooGameStatus.inProgress:
        body = _PlayingView(key: const ValueKey('playing'), match: match);
      case TabooGameStatus.roundEnded:
      case TabooGameStatus.gameFinished:
        body = const _TimeUpView(key: ValueKey('timeUp'));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(match: match, onExit: _requestExit),
                const SizedBox(height: AppSpacing.m),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.base,
                    switchInCurve: AppMotion.standardCurve,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Üst panel: çıkış, aktif takım + tur numarası, kalan süre.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.match, required this.onExit});

  final TabooMatch match;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final teamColor = tabooTeamColor(match.activeTeamIndex);
    return Row(
      children: [
        IconButton(
          onPressed: onExit,
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          tooltip: 'Oyundan çık',
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.activeTeam.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title.copyWith(color: teamColor),
              ),
              Text(
                '${match.roundNumber}. Tur · Hedef ${match.settings.targetScore}',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        _TimerPill(match: match),
      ],
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.match});

  final TabooMatch match;

  @override
  Widget build(BuildContext context) {
    final seconds = match.remainingSeconds;
    final isUrgent = match.status == TabooGameStatus.inProgress &&
        seconds <= TabooGameNotifier.finalCountdownSeconds;
    final color = isUrgent ? AppColors.error : AppColors.primary;
    final text = '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';

    return Semantics(
      label: 'Kalan süre: $seconds saniye',
      liveRegion: isUrgent,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standardCurve,
        constraints: const BoxConstraints(minWidth: _timerPillMinWidth),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppShadows.glow(color, isUrgent ? 0.5 : 0.25),
              blurRadius: isUrgent ? 20 : 12,
            ),
          ],
        ),
        child: AnimatedScale(
          // Son saniyelerde her saniye kısa bir "vuruş".
          scale: isUrgent && seconds.isOdd ? 1.12 : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          child: Text(
            text,
            style: AppTypography.headline.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tur başlamadan önce: sıradaki takım ve "Başla" butonu.
class _ReadyView extends StatelessWidget {
  const _ReadyView({super.key, required this.match, required this.onStart});

  final TabooMatch match;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final teamColor = tabooTeamColor(match.activeTeamIndex);
    final passText = match.settings.passLimit == 0
        ? 'Bu oyunda pas hakkı yok.'
        : 'Turda ${match.settings.passLimit} pas hakkınız var.';

    // Skor tablosu da kaydırılabilir alanda: küçük ekranda ve büyük yazı
    // boyutunda taşma olmaz; "Başla" her zaman altta görünür.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabooScoreboard(match: match),
                const SizedBox(height: AppSpacing.xl),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SIRA',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      match.activeTeam.name.toUpperTr(),
                      textAlign: TextAlign.center,
                      style: AppTypography.gameDisplay.copyWith(
                        color: teamColor,
                        shadows: [
                          Shadow(
                            color: AppShadows.glow(teamColor, _targetGlowAlpha),
                            blurRadius: _targetGlowBlur,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Text(
                      'Anlatıcı telefonu alsın.\n'
                      'Takım arkadaşları ekranı görmesin!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      '${match.settings.roundDurationSeconds} saniye · $passText',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        AppButton(
          label: 'Başla',
          variant: ButtonVariant.primary,
          fullWidth: true,
          onPressed: onStart,
        ),
      ],
    );
  }
}

/// Tur sırasında: kompakt skor, kart, tur istatistiği ve aksiyon butonları.
class _PlayingView extends ConsumerWidget {
  const _PlayingView({super.key, required this.match});

  final TabooMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tabooGameProvider.notifier);
    final card = match.currentCard;
    final categoryNames = ref.watch(tabooWordRepositoryProvider).categoryNames;
    final passesLeft = match.activeTeam.passesLeft;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dikey alan darsa (küçük ekran / büyük yazı) tur istatistiği gizlenir;
        // kart ve aksiyon butonları her zaman görünür kalır. İstatistikler
        // tur sonu ekranında ayrıntılı gösterilir.
        final showStats = constraints.maxHeight >= _statsMinHeight;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabooScoreboard(match: match, compact: true),
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.base,
                switchInCurve: AppMotion.standardCurve,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _cardTransition,
                child: card == null
                    ? const SizedBox.shrink()
                    : _TabooCardView(
                        key: ValueKey(card.id),
                        card: card,
                        categoryName: categoryNames[card.categoryId] ?? '',
                      ),
              ),
            ),
            if (showStats) ...[
              const SizedBox(height: AppSpacing.m),
              _TurnStats(match: match),
            ],
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Tabu!',
                    dense: true,
                    variant: ButtonVariant.danger,
                    fullWidth: true,
                    // Titreşim (heavyImpact) notifier'da tetiklenir.
                    haptics: false,
                    onPressed: notifier.markTaboo,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: AppButton(
                    label: 'Pas ($passesLeft)',
                    dense: true,
                    variant: ButtonVariant.warning,
                    fullWidth: true,
                    haptics: false,
                    onPressed: passesLeft > 0 ? notifier.pass : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: AppButton(
                    label: 'Doğru',
                    dense: true,
                    variant: ButtonVariant.primary,
                    fullWidth: true,
                    // Titreşim (lightImpact) notifier'da tetiklenir.
                    haptics: false,
                    onPressed: notifier.markCorrect,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Yeni kart alttan hafifçe yükselip büyüyerek gelir; eskisi solar.
Widget _cardTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, _cardEntryOffset),
        end: Offset.zero,
      ).animate(animation),
      child: ScaleTransition(
        scale: Tween<double>(begin: _cardEntryScale, end: 1).animate(animation),
        child: child,
      ),
    ),
  );
}

/// Devasa kart: parlayan ana kelime + kırmızı yasaklı kelimeler.
///
/// Kart her zaman ekrandaki boş alanın tamamını kaplar. İçerik doğal
/// boyutunda tasarlanır; alan yetmezse (küçük telefon, büyük sistem yazı
/// boyutu) bütün olarak orantılı küçülür, böylece hiçbir kelime kesilmez.
class _TabooCardView extends StatelessWidget {
  const _TabooCardView({
    super.key,
    required this.card,
    required this.categoryName,
  });

  final TabooCard card;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AppCard(
        variant: CardVariant.highlighted,
        padding: const EdgeInsets.all(AppSpacing.l),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: constraints.maxWidth,
                child: _CardContent(card: card, categoryName: categoryName),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.card, required this.categoryName});

  final TabooCard card;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$categoryName · ${card.difficulty.label}'.toUpperTr(),
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.m),
        Semantics(
          header: true,
          label: 'Anlatılacak kelime: ${card.targetWord}',
          excludeSemantics: true,
          // Uzun kelimeler ("Akıllı Telefon") kart genişliğine sığacak
          // kadar küçülür.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.targetWord.toUpperTr(),
              textAlign: TextAlign.center,
              style: AppTypography.gameDisplay.copyWith(
                color: AppColors.primary,
                shadows: [
                  Shadow(
                    color: AppShadows.glow(AppColors.primary, _targetGlowAlpha),
                    blurRadius: _targetGlowBlur,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: AppSpacing.m),
        Text(
          'YASAKLI KELİMELER',
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.s),
        Semantics(
          label: 'Yasaklı kelimeler: ${card.forbiddenWords.join(', ')}',
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final word in card.forbiddenWords)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word,
                      textAlign: TextAlign.center,
                      style: AppTypography.headline.copyWith(
                        color: AppColors.error,
                        shadows: [
                          Shadow(
                            color: AppShadows.glow(
                                AppColors.error, _forbiddenGlowAlpha),
                            blurRadius: _forbiddenGlowBlur,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tur içi sayaçlar: doğru / tabu / pas.
class _TurnStats extends StatelessWidget {
  const _TurnStats({required this.match});

  final TabooMatch match;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatChip(
          icon: Icons.check_circle,
          color: AppColors.primary,
          value: match.countOf(TabooOutcome.correct),
          label: 'doğru',
        ),
        const SizedBox(width: AppSpacing.l),
        _StatChip(
          icon: Icons.block,
          color: AppColors.error,
          value: match.countOf(TabooOutcome.taboo),
          label: 'tabu',
        ),
        const SizedBox(width: AppSpacing.l),
        _StatChip(
          icon: Icons.skip_next,
          color: AppColors.warning,
          value: match.countOf(TabooOutcome.pass),
          label: 'pas',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _statIconSize, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text('$value', style: AppTypography.title.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Süre bittiği an: sonuç ekranına geçmeden önceki kısa vurgu.
class _TimeUpView extends StatelessWidget {
  const _TimeUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: AppMotion.resolve(context, AppMotion.dramatic),
        curve: AppMotion.dramaticCurve,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.alarm,
              size: AppSpacing.xxl,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'SÜRE BİTTİ!',
              textAlign: TextAlign.center,
              style: AppTypography.gameDisplay.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aktif maç yokken (örn. doğrudan adrese gidildiyse) güvenli boş durum.
class _MissingMatchView extends StatelessWidget {
  const _MissingMatchView({required this.onBack});

  final VoidCallback onBack;

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
                'Aktif bir Tabu maçı bulunamadı.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Tabu Kurulumuna Dön',
                variant: ButtonVariant.primary,
                fullWidth: true,
                onPressed: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
