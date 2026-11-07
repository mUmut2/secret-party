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
import '../../../domain/models/werewolf/werewolf_game_state.dart';
import '../../../domain/models/werewolf/werewolf_player.dart';
import '../../../domain/models/werewolf/werewolf_role.dart';
import '../viewmodels/werewolf_game_notifier.dart';
import '../viewmodels/werewolf_pass_flow_notifier.dart';
import '../widgets/werewolf_death_card.dart';
import '../widgets/werewolf_dialogs.dart';
import '../widgets/werewolf_hunter_decision.dart';
import '../widgets/werewolf_missing_game_view.dart';
import '../../../core/widgets/app_pass_gate.dart';
import '../widgets/werewolf_player_picker.dart';

const double _heroIconSize = 56;
const double _tallyBarHeight = 8;

/// Gündüz: BİREYSEL GİZLİ OYLAMA (sıralı tek telefon).
///
/// 1. Telefon sırayla yaşayan her oyuncuya verilir; KİLİTLİ ekran basılı
///    tutularak açılır.
/// 2. Oyuncu diğerlerine göstermeden kendisi dışındaki birine oy verir ve
///    "Oyumu Kullandım, Telefonu Ayşe'ye Ver" ile telefonu devreder.
/// 3. Son oyla birlikte oylar otomatik sayılır; telefon ortaya konunca
///    sonuç herkese açılır. En çok oy alan sürgün edilir; eşitlikte ayara
///    göre kimse elenmez ya da kura çekilir.
/// 4. Sürülen avcıysa "Avcı Elendi!" kararı alınır.
class WerewolfVotingScreen extends ConsumerWidget {
  const WerewolfVotingScreen({super.key});

  Future<void> _requestExit(BuildContext context, WidgetRef ref) async {
    final approved = await confirmWerewolfExit(context);
    if (!approved || !context.mounted) return;
    ref.read(werewolfGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(werewolfGameProvider);
    final flow = ref.watch(werewolfPassFlowProvider);
    if (game == null) return const WerewolfMissingGameView();

    final flowNotifier = ref.read(werewolfPassFlowProvider.notifier);
    final voter = game.currentTurnPlayer;

    final Widget body;
    final String bodyKey;
    if (game.voteResolved && flow.resultsRevealed) {
      bodyKey = 'verdict';
      body = _VerdictView(game: game);
    } else if (game.voteResolved) {
      bodyKey = 'allVoted';
      body = _AllVotedView(onReveal: flowNotifier.revealResults);
    } else if (!flow.introSeen && game.turnIndex == 0) {
      bodyKey = 'intro';
      body = _VotingIntro(
        game: game,
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
                        '${game.dayNumber}. GÜN OYLAMASI',
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

class _VotingIntro extends StatelessWidget {
  const _VotingIntro({required this.game, required this.onBegin});

  final WerewolfGameState game;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final tieRule = game.settings.tieBreak == WerewolfTieBreak.randomDraw
        ? 'Eşitlikte berabere kalanlar arasında kura çekilir.'
        : 'Eşitlikte kimse sürgün edilmez.';
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
                    Icons.how_to_vote,
                    size: _heroIconSize,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  const Text(
                    'Bireysel Gizli Oylama',
                    textAlign: TextAlign.center,
                    style: AppTypography.display,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Telefon sırayla yaşayan ${game.turnOrder.length} kişiye '
                    'verilecek. Herkes kimseye göstermeden, kendisi dışındaki '
                    'bir oyuncuya oy verecek.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'En çok oy alan köyden sürgün edilir. $tieRule',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        AppButton(
          label: 'Oylamayı Başlat',
          variant: ButtonVariant.secondary,
          fullWidth: true,
          onPressed: onBegin,
        ),
      ],
    );
  }
}

/// Sırası gelen seçmenin gizli oy pusulası.
class _BallotView extends ConsumerStatefulWidget {
  const _BallotView({required this.game, required this.voter});

  final WerewolfGameState game;
  final WerewolfPlayer voter;

  @override
  ConsumerState<_BallotView> createState() => _BallotViewState();
}

class _BallotViewState extends ConsumerState<_BallotView> {
  String? _targetId;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final next = game.nextTurnPlayer;
    final options =
        ref.read(werewolfEngineProvider).voteOptions(game, widget.voter.id);

    // Başlık ve açıklama da kaydırılabilir alanda: büyük yazı boyutunda
    // seçim listesi sıkışmaz, yalnızca alttaki buton sabit kalır.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.voter.name}, kimi sürgün etmek istiyorsun?',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Oyun gizli. Kimse kimin kime oy verdiğini görmeyecek.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.m),
                WerewolfPlayerPicker(
                  players: options,
                  selectedId: _targetId,
                  accentColor: AppColors.secondary,
                  semanticAction: 'oy ver',
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
              : () => ref.read(werewolfGameProvider.notifier).castVote(
                    _targetId!,
                  ),
        ),
      ],
    );
  }
}

/// Son oy verildi: telefon ortaya konup sonuç birlikte açılır.
class _AllVotedView extends StatelessWidget {
  const _AllVotedView({required this.onReveal});

  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    'Oylar sayıldı. Telefonu herkesin görebileceği şekilde '
                    'ortaya koyun ve sonucu birlikte açın.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        AppButton(
          label: 'Sonucu Açıkla',
          variant: ButtonVariant.secondary,
          fullWidth: true,
          onPressed: onReveal,
        ),
      ],
    );
  }
}

/// Sayım sonucu: oy dağılımı, sürgün, avcı kararı ve sonraki adım.
class _VerdictView extends ConsumerWidget {
  const _VerdictView({required this.game});

  final WerewolfGameState game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exiled = game.tryPlayerById(game.lastExiledId);
    final hunterVictim = _hunterVictimAfterExile(game);
    final tally = game.voteTally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVotes = tally.isEmpty ? 1 : tally.first.value;

    final String headline;
    final String subline;
    if (exiled != null && game.voteWasTie) {
      headline = 'Eşitlik! Kura Çekildi';
      subline = 'Berabere kalanlar arasından kura ile biri seçildi.';
    } else if (exiled != null) {
      headline = 'Köy Kararını Verdi';
      subline = 'En çok oyu alan köyden sürgün edildi.';
    } else {
      headline = 'Eşitlik! Kimse Elenmedi';
      subline = 'Oylar eşit dağıldı; köy bugün kimseyi sürgün etmedi.';
    }

    final Widget button;
    if (game.isFinished) {
      button = AppButton(
        label: 'Sonuçları Gör',
        variant: ButtonVariant.primary,
        fullWidth: true,
        onPressed: () => context.go(AppRouter.werewolfResult),
      );
    } else {
      button = AppButton(
        label: 'Geceye Geç',
        variant: ButtonVariant.night,
        fullWidth: true,
        onPressed: game.hasPendingHunterDecision
            ? null
            : () {
                ref.read(werewolfGameProvider.notifier).startNight();
                context.go(AppRouter.werewolfNight);
              },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              Icon(
                exiled == null ? Icons.balance : Icons.gavel,
                size: _heroIconSize,
                color: exiled == null ? AppColors.warning : AppColors.secondary,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTypography.display,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subline,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.l),
              if (exiled != null) ...[
                WerewolfDeathCard(
                  player: exiled,
                  message: 'Köyden sürgün edildi.',
                  revealRole: game.settings.revealRoleOnDeath ||
                      exiled.role == WerewolfRole.avci,
                ),
                const SizedBox(height: AppSpacing.l),
              ],
              if (game.hasPendingHunterDecision) ...[
                WerewolfHunterDecision(game: game),
                const SizedBox(height: AppSpacing.l),
              ],
              if (hunterVictim != null) ...[
                WerewolfDeathCard(
                  player: hunterVictim,
                  message: WerewolfDeathCause.hunter.label,
                  revealRole: game.settings.revealRoleOnDeath,
                ),
                const SizedBox(height: AppSpacing.l),
              ],
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
                        highlighted: entry.key == game.lastExiledId,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        button,
      ],
    );
  }

  /// Sürgünden SONRA yapılmış avcı atışının kurbanı.
  WerewolfPlayer? _hunterVictimAfterExile(WerewolfGameState game) {
    final exiledId = game.lastExiledId;
    if (exiledId == null) return null;
    final exileIndex = game.deaths.indexWhere(
      (d) => d.playerId == exiledId && d.cause == WerewolfDeathCause.exile,
    );
    if (exileIndex < 0) return null;
    final shot = game.deaths
        .skip(exileIndex + 1)
        .where((d) => d.cause == WerewolfDeathCause.hunter)
        .firstOrNull;
    return shot == null ? null : game.playerById(shot.playerId);
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
