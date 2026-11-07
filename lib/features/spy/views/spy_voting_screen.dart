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
import '../../../core/widgets/app_pass_gate.dart';
import '../../../core/widgets/app_player_picker.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/spy/spy_game_state.dart';
import '../../../domain/models/spy/spy_player.dart';
import '../viewmodels/spy_flow_notifiers.dart';
import '../viewmodels/spy_game_notifier.dart';
import '../widgets/spy_dialogs.dart';
import '../widgets/spy_missing_game_view.dart';

const double _heroIconSize = 56;
const double _tallyBarHeight = 8;
const double _accusedAvatarSize = 56;

/// Bireysel gizli oylama (sıralı tek telefon).
///
/// 1. Telefon sırayla herkese verilir; KİLİTLİ ekran basılı tutularak açılır.
/// 2. Oyuncu kendisi dışındaki birini gizlice seçer ve "Oyumu Kullandım,
///    Telefonu Ayşe'ye Ver" ile devreder.
/// 3. Son oyla sayım otomatik yapılır; telefon ortaya konup sonuç açılır:
///    - Ajan yakalandıysa → son şans tahmin ekranı.
///    - Masum suçlandıysa ya da eşitlik varsa → Ajan kazandı.
class SpyVotingScreen extends ConsumerWidget {
  const SpyVotingScreen({super.key});

  Future<void> _requestExit(BuildContext context, WidgetRef ref) async {
    final approved = await confirmSpyExit(context);
    if (!approved || !context.mounted) return;
    ref.read(spyGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(spyGameProvider);
    final flow = ref.watch(spyVoteFlowProvider);
    if (game == null) return const SpyMissingGameView();

    final flowNotifier = ref.read(spyVoteFlowProvider.notifier);
    final voter = game.currentVoter;

    final Widget body;
    final String bodyKey;
    if (game.hasVoted && flow.resultsRevealed) {
      bodyKey = 'verdict';
      body = _VerdictView(game: game);
    } else if (game.hasVoted) {
      bodyKey = 'allVoted';
      body = _AllVotedView(onReveal: flowNotifier.revealResults);
    } else if (!flow.introSeen && game.turnIndex == 0) {
      bodyKey = 'intro';
      body = _VotingIntro(
        playerCount: game.turnOrder.length,
        onBegin: flowNotifier.dismissIntro,
      );
    } else if (voter == null) {
      bodyKey = 'empty';
      body = const SizedBox.shrink();
    } else if (!flow.isUnlocked(game.turnIndex)) {
      bodyKey = 'gate_${game.turnIndex}';
      body = AppPassGate(
        playerName: voter.name,
        instruction: 'telefonu al ve oyunu gizlice kullan.',
        accentColor: AppColors.secondary,
        progressLabel: '${game.turnIndex + 1}/${game.turnOrder.length}',
        onUnlocked: () => flowNotifier.unlock(game),
      );
    } else {
      bodyKey = 'ballot_${game.turnIndex}';
      body = _BallotView(game: game, voter: voter);
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
                    const Icon(Icons.how_to_vote, color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'AJAN OYLAMASI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.slow,
                    switchInCurve: AppMotion.standardCurve,
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

/// Ortada içerik, altta tek buton.
class _CenteredStep extends StatelessWidget {
  const _CenteredStep({required this.children, required this.button});

  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        button,
      ],
    );
  }
}

class _VotingIntro extends StatelessWidget {
  const _VotingIntro({required this.playerCount, required this.onBegin});

  final int playerCount;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return _CenteredStep(
      button: AppButton(
        label: 'Oylamayı Başlat',
        variant: ButtonVariant.secondary,
        fullWidth: true,
        onPressed: onBegin,
      ),
      children: [
        const Icon(
          Icons.how_to_vote,
          size: _heroIconSize,
          color: AppColors.secondary,
        ),
        const SizedBox(height: AppSpacing.m),
        const Text(
          'Ajan Kim?',
          textAlign: TextAlign.center,
          style: AppTypography.display,
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          'Telefon sırayla $playerCount kişiye verilecek. Herkes ajan '
          'olduğuna inandığı kişiyi gizlice seçecek.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.s),
        const Text(
          'Masum biri suçlanırsa ya da oylar eşit çıkarsa ajan kazanır. '
          'Ajan yakalanırsa konumu tahmin etmek için son bir şansı olur.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

class _BallotView extends ConsumerStatefulWidget {
  const _BallotView({required this.game, required this.voter});

  final SpyGameState game;
  final SpyPlayer voter;

  @override
  ConsumerState<_BallotView> createState() => _BallotViewState();
}

class _BallotViewState extends ConsumerState<_BallotView> {
  String? _targetId;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final next = game.nextVoter;
    final options =
        ref.read(spyEngineProvider).voteOptions(game, widget.voter.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.voter.name}, sence ajan kim?',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Oyun gizli. Kimse kimin kime oy verdiğini görmeyecek.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.m),
                AppPlayerPicker(
                  entries: [
                    for (final p in options)
                      AppPickerEntry(id: p.id, name: p.name),
                  ],
                  selectedId: _targetId,
                  accentColor: AppColors.secondary,
                  semanticAction: 'ajan olarak oyla',
                  onSelected: (id) => setState(() => _targetId = id),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        AppButton(
          label: next == null
              ? 'Oyumu Kullandım'
              : 'Oyumu Kullandım, Telefonu ${next.name.withDativeSuffix()} Ver',
          variant: ButtonVariant.secondary,
          fullWidth: true,
          // Titreşim notifier'da tetiklenir.
          haptics: false,
          onPressed: _targetId == null
              ? null
              : () => ref.read(spyGameProvider.notifier).castVote(_targetId!),
        ),
      ],
    );
  }
}

class _AllVotedView extends StatelessWidget {
  const _AllVotedView({required this.onReveal});

  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return _CenteredStep(
      button: AppButton(
        label: 'Sonucu Açıkla',
        variant: ButtonVariant.secondary,
        fullWidth: true,
        onPressed: onReveal,
      ),
      children: const [
        Icon(
          Icons.inventory_2,
          size: _heroIconSize,
          color: AppColors.secondary,
        ),
        SizedBox(height: AppSpacing.m),
        Text(
          'Tüm Oylar Kullanıldı',
          textAlign: TextAlign.center,
          style: AppTypography.display,
        ),
        SizedBox(height: AppSpacing.m),
        Text(
          'Oylar sayıldı. Telefonu herkesin görebileceği şekilde ortaya '
          'koyun ve sonucu birlikte açın.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}

/// Sayım sonucu: suçlanan kişi, oy dağılımı ve sonraki adım.
class _VerdictView extends StatelessWidget {
  const _VerdictView({required this.game});

  final SpyGameState game;

  @override
  Widget build(BuildContext context) {
    final accused = game.accused;
    final caughtSpy = game.phase == SpyPhase.spyGuessing;
    final tally = game.voteTally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVotes = tally.isEmpty ? 1 : tally.first.value;

    final String headline;
    final String message;
    final Color color;
    if (accused == null) {
      headline = 'Eşitlik!';
      message = 'Oylar eşit dağıldı; köy kimseyi suçlayamadı. Ajan '
          'gölgelerde kaldı.';
      color = AppColors.warning;
    } else if (caughtSpy) {
      headline = 'AJAN YAKALANDI!';
      message = '${accused.name} gerçekten ajan! Ama konumu doğru tahmin '
          'ederse yine de kazanır.';
      color = AppColors.primary;
    } else {
      headline = '${accused.name} Masumdu!';
      message = 'Köy yanlış kişiyi suçladı. Ajan kazandı!';
      color = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              if (accused != null)
                Center(
                  child: PlayerAvatar(
                    name: accused.name,
                    size: _accusedAvatarSize,
                    state:
                        caughtSpy ? AvatarState.imposter : AvatarState.selected,
                  ),
                )
              else
                const Icon(
                  Icons.balance,
                  size: _heroIconSize,
                  color: AppColors.warning,
                ),
              const SizedBox(height: AppSpacing.m),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTypography.display.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.l),
              const Text('Oy Dağılımı', style: AppTypography.title),
              const SizedBox(height: AppSpacing.s),
              AppCard(
                child: Column(
                  children: [
                    for (final entry in tally)
                      _TallyRow(
                        name: game.playerById(entry.key).name,
                        votes: entry.value,
                        fraction: entry.value / maxVotes,
                        highlighted: entry.key == game.accusedId,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        if (caughtSpy)
          AppButton(
            label: 'Ajanın Son Tahmini',
            variant: ButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.go(AppRouter.spyGuess),
          )
        else
          AppButton(
            label: 'Sonuçları Gör',
            variant: ButtonVariant.primary,
            fullWidth: true,
            onPressed: () => context.go(AppRouter.spyResult),
          ),
      ],
    );
  }
}

class _TallyRow extends StatelessWidget {
  const _TallyRow({
    required this.name,
    required this.votes,
    required this.fraction,
    required this.highlighted,
  });

  final String name;
  final int votes;
  final double fraction;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.secondary : AppColors.textSecondary;
    return Semantics(
      label: '$name: $votes oy',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge,
                  ),
                ),
                Text(
                  '$votes oy',
                  style: AppTypography.label.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: AppMotion.dramatic,
                curve: AppMotion.standardCurve,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: _tallyBarHeight,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
