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
import '../../../core/widgets/app_pass_gate.dart';
import '../../../domain/models/spy/spy_game_state.dart';
import '../../../domain/models/spy/spy_player.dart';
import '../viewmodels/spy_flow_notifiers.dart';
import '../viewmodels/spy_game_notifier.dart';
import '../viewmodels/spy_timer_notifier.dart';
import '../widgets/spy_dialogs.dart';
import '../widgets/spy_missing_game_view.dart';

const double _cardBorderWidth = 2;
const double _cardIconSize = 56;
const double _cardMaxHeight = 460;
const double _glowBlur = 28;
const double _textGlowBlur = 22;

/// Rol öğrenme (sıralı tek telefon).
///
/// Her oyuncu için: KİLİTLİ "Telefonu Ayşe'ye Ver" ekranı → basılı tutarak
/// açılan rol kartı → "Gördüm, Telefonu Can'a Ver". Masumlar konumu ve
/// rollerini lime neonla; ajan ise uyarısını fuşya/kırmızı neonla görür.
class SpyRoleRevealScreen extends ConsumerWidget {
  const SpyRoleRevealScreen({super.key});

  Future<void> _requestExit(BuildContext context, WidgetRef ref) async {
    final approved = await confirmSpyExit(context);
    if (!approved || !context.mounted) return;
    ref.read(spyGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  void _startRound(BuildContext context, WidgetRef ref, SpyGameState game) {
    ref.read(spyGameProvider.notifier).startRound();
    ref.read(spyTimerProvider.notifier).start(game.settings.discussionSeconds);
    context.go(AppRouter.spyGame);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(spyGameProvider);
    final reveal = ref.watch(spyRevealProvider);
    if (game == null) return const SpyMissingGameView();

    final notifier = ref.read(spyRevealProvider.notifier);
    final total = game.players.length;
    final player = game.players[reveal.currentIndex.clamp(0, total - 1)];

    final Widget body;
    final String bodyKey;
    if (reveal.allRevealed) {
      bodyKey = 'done';
      body = _AllRevealedStep(
        game: game,
        onStart: () => _startRound(context, ref, game),
      );
    } else if (!reveal.isUnlocked) {
      bodyKey = 'gate_${reveal.currentIndex}';
      body = AppPassGate(
        playerName: player.name,
        instruction: 'telefonu al ve rolünü gizlice öğren.',
        progressLabel: '${reveal.currentIndex + 1}/$total',
        onUnlocked: notifier.unlock,
      );
    } else {
      final next = reveal.currentIndex + 1 < total
          ? game.players[reveal.currentIndex + 1]
          : null;
      bodyKey = 'card_${reveal.currentIndex}';
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _cardMaxHeight),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1),
                  duration: AppMotion.resolve(context, AppMotion.dramatic),
                  curve: AppMotion.dramaticCurve,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: player.isSpy
                      ? const _SpyCard()
                      : _InnocentCard(game: game, player: player),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            label: next == null
                ? 'Gördüm, Bitir'
                : 'Gördüm, Telefonu ${next.name.withDativeSuffix()} Ver',
            variant: ButtonVariant.primary,
            fullWidth: true,
            onPressed: () => notifier.confirmSeen(totalPlayers: total),
          ),
        ],
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit(context, ref);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Text(
                      'ROL ÖĞRENME',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.slow,
                    child: KeyedSubtree(key: ValueKey(bodyKey), child: body),
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

BoxDecoration _neonCard(Color color) => BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: color, width: _cardBorderWidth),
      boxShadow: [
        BoxShadow(color: AppShadows.glow(color, 0.45), blurRadius: _glowBlur),
      ],
    );

TextStyle _glowing(TextStyle base, Color color) => base.copyWith(
      color: color,
      shadows: [
        Shadow(color: AppShadows.glow(color, 0.6), blurRadius: _textGlowBlur),
      ],
    );

/// İçerik doğal boyutunda tasarlanır; alan yetmezse bütün olarak küçülür.
class _FittedCard extends StatelessWidget {
  const _FittedCard({required this.color, required this.children});

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: _neonCard(color),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _InnocentCard extends StatelessWidget {
  const _InnocentCard({required this.game, required this.player});

  final SpyGameState game;
  final SpyPlayer player;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    return Semantics(
      label: 'Konum: ${game.location.name}. Rolün: ${player.roleName}.',
      excludeSemantics: true,
      child: _FittedCard(
        color: color,
        children: [
          const Icon(Icons.place, size: _cardIconSize, color: color),
          const SizedBox(height: AppSpacing.m),
          Text(
            'KONUM',
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            game.location.name.toUpperTr(),
            textAlign: TextAlign.center,
            style: _glowing(AppTypography.gameDisplay, color),
          ),
          const SizedBox(height: AppSpacing.l),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.l),
          Text(
            'ROLÜN',
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            player.roleName ?? '',
            textAlign: TextAlign.center,
            style: _glowing(AppTypography.display, AppColors.tertiary),
          ),
          const SizedBox(height: AppSpacing.l),
          const Text(
            'Ajan konumu bilmiyor. Sorularını ona ipucu vermeden sor!',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SpyCard extends StatelessWidget {
  const _SpyCard();

  @override
  Widget build(BuildContext context) {
    const color = AppColors.secondary;
    return Semantics(
      label: 'Sen ajansın. Konum gizli.',
      excludeSemantics: true,
      child: _FittedCard(
        color: color,
        children: [
          const Icon(Icons.policy, size: _cardIconSize, color: color),
          const SizedBox(height: AppSpacing.m),
          Text(
            'SEN AJANSIN!',
            textAlign: TextAlign.center,
            style: _glowing(AppTypography.gameDisplay, color),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'KONUM GİZLİ',
            style: _glowing(AppTypography.title, AppColors.error),
          ),
          const SizedBox(height: AppSpacing.l),
          const Text(
            'Sorulardan konumu tahmin etmeye çalış! Kendini belli etme; '
            'emin olduğunda oyunu durdurup konumu söyle.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _AllRevealedStep extends StatelessWidget {
  const _AllRevealedStep({required this.game, required this.onStart});

  final SpyGameState game;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups,
                    size: _cardIconSize,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  const Text(
                    'Herkes rolünü öğrendi',
                    textAlign: TextAlign.center,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Telefonu ortaya koyun. Sayaç başlayınca ilk soruyu '
                    '${game.firstAsker.name} soracak.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        AppButton(
          label: 'Oyunu Başlat',
          variant: ButtonVariant.primary,
          fullWidth: true,
          onPressed: onStart,
        ),
      ],
    );
  }
}
