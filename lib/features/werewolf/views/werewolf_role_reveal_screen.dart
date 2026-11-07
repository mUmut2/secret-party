import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/models/werewolf/werewolf_game_state.dart';
import '../../../domain/models/werewolf/werewolf_player.dart';
import '../viewmodels/werewolf_game_notifier.dart';
import '../viewmodels/werewolf_reveal_notifier.dart';
import '../widgets/werewolf_dialogs.dart';
import '../widgets/werewolf_missing_game_view.dart';
import '../../../core/widgets/app_pass_gate.dart';
import '../widgets/werewolf_role_style.dart';

const double _cardBorderWidth = 2;
const double _hiddenIconSize = 72;
const double _roleIconSize = 64;
const double _cardMaxHeight = 440;

/// Rol öğrenme fazı (sıralı tek telefon).
///
/// Telefon 1. oyuncudan başlar. Her oyuncu için:
/// 1. KİLİTLİ geçiş ekranı: "Telefonu Ayşe'ye Ver" + basılı tutmalı onay.
/// 2. Rol kartı: yalnızca karta BASILI TUTULDUĞU sürece görünür.
/// 3. "Rolümü Gördüm" → sıradaki oyuncunun kilitli geçiş ekranı.
/// Vampirler kartlarında diğer vampirleri de görür.
class WerewolfRoleRevealScreen extends ConsumerWidget {
  const WerewolfRoleRevealScreen({super.key});

  Future<void> _requestExit(BuildContext context, WidgetRef ref) async {
    final approved = await confirmWerewolfExit(context);
    if (!approved || !context.mounted) return;
    ref.read(werewolfGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(werewolfGameProvider);
    final reveal = ref.watch(werewolfRevealProvider);
    if (game == null) return const WerewolfMissingGameView();

    final notifier = ref.read(werewolfRevealProvider.notifier);
    final total = game.players.length;
    final player = game.players[reveal.currentIndex.clamp(0, total - 1)];

    final Widget body;
    final String bodyKey;
    if (reveal.allRevealed) {
      bodyKey = 'done';
      body = _AllRevealedStep(
        playerCount: total,
        onStartNight: () {
          ref.read(werewolfGameProvider.notifier).startNight();
          context.go(AppRouter.werewolfNight);
        },
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
      bodyKey = 'card_${reveal.currentIndex}';
      body = _RoleCardStep(
        game: game,
        player: player,
        reveal: reveal,
        isLast: reveal.currentIndex == total - 1,
        onConfirm: () => notifier.confirmSeen(totalPlayers: total),
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

class _RoleCardStep extends ConsumerWidget {
  const _RoleCardStep({
    required this.game,
    required this.player,
    required this.reveal,
    required this.isLast,
    required this.onConfirm,
  });

  final WerewolfGameState game;
  final WerewolfPlayer player;
  final WerewolfRevealState reveal;
  final bool isLast;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(werewolfRevealProvider.notifier);
    final fellowVampires = player.isVampire
        ? game.players
            .where((p) => p.isVampire && p.id != player.id)
            .map((p) => p.name)
            .toList()
        : const <String>[];
    final next = isLast ? null : game.players[reveal.currentIndex + 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s),
        Text(
          '${player.name}, rolünü görmek için karta basılı tut',
          textAlign: TextAlign.center,
          style: AppTypography.title,
        ),
        const SizedBox(height: AppSpacing.m),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _cardMaxHeight),
              child: _HoldToRevealCard(
                player: player,
                fellowVampires: fellowVampires,
                isRevealed: reveal.isPeeking,
                onPressStart: notifier.startPeek,
                onPressEnd: notifier.endPeek,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        AppButton(
          label: next == null
              ? 'Rolümü Gördüm, Bitir'
              : 'Rolümü Gördüm, Telefonu ${next.name.withDativeSuffix()} Ver',
          variant: ButtonVariant.primary,
          fullWidth: true,
          onPressed: reveal.hasSeenRole && !reveal.isPeeking ? onConfirm : null,
        ),
      ],
    );
  }
}

/// Basılı tutulunca Y ekseninde dönen Neon Ink rol kartı.
///
/// `Listener` kullanılır (GestureDetector değil): uzun basışta jest arenası
/// dokunuşu iptal edip kartı erken kapatmasın.
class _HoldToRevealCard extends StatelessWidget {
  const _HoldToRevealCard({
    required this.player,
    required this.fellowVampires,
    required this.isRevealed,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final WerewolfPlayer player;
  final List<String> fellowVampires;
  final bool isRevealed;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isRevealed
          ? 'Rolün: ${player.role.label}. ${player.role.description}'
          : 'Rolünü görmek için basılı tut',
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => onPressStart(),
        onPointerUp: (_) => onPressEnd(),
        onPointerCancel: (_) => onPressEnd(),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: isRevealed ? 1 : 0),
          duration: AppMotion.slow,
          curve: AppMotion.standardCurve,
          builder: (context, t, _) {
            final showFront = t >= 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(t * math.pi),
              child: showFront
                  // Ön yüz ayna görüntüsü olmasın diye 180° geri çevrilir.
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _RoleFace(
                        player: player,
                        fellowVampires: fellowVampires,
                      ),
                    )
                  : const _HiddenFace(),
            );
          },
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({
  required Color background,
  required Color border,
  required List<BoxShadow> shadow,
}) {
  return BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: Border.all(color: border, width: _cardBorderWidth),
    boxShadow: shadow,
  );
}

class _HiddenFace extends StatelessWidget {
  const _HiddenFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: _cardDecoration(
        background: AppColors.nightSurface,
        border: AppColors.nightAccent,
        shadow: AppShadows.glowNight,
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fingerprint,
              size: _hiddenIconSize,
              color: AppColors.nightAccent,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'BASILI TUT',
              style: AppTypography.headline.copyWith(
                color: AppColors.nightAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Parmağını kaldırınca rol gizlenir.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleFace extends StatelessWidget {
  const _RoleFace({required this.player, required this.fellowVampires});

  final WerewolfPlayer player;
  final List<String> fellowVampires;

  @override
  Widget build(BuildContext context) {
    final role = player.role;
    final color = role.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: _cardDecoration(
        background: AppColors.surfaceElevated,
        border: color,
        shadow: [
          BoxShadow(color: AppShadows.glow(color, 0.45), blurRadius: 28),
        ],
      ),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(role.icon, size: _roleIconSize, color: color),
                const SizedBox(height: AppSpacing.m),
                Text(
                  role.label.toUpperTr(),
                  textAlign: TextAlign.center,
                  style: AppTypography.gameDisplay.copyWith(
                    color: color,
                    shadows: [
                      Shadow(
                        color: AppShadows.glow(color, 0.55),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  role.team.label.toUpperTr(),
                  style: AppTypography.label.copyWith(color: role.team.color),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  role.description,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Hedef: ${role.goal}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                if (player.isVampire) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    fellowVampires.isEmpty
                        ? 'Tek vampir sensin. Kimseye güvenme.'
                        : 'Diğer vampirler: ${fellowVampires.join(', ')}',
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(color: color),
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

class _AllRevealedStep extends StatelessWidget {
  const _AllRevealedStep({
    required this.playerCount,
    required this.onStartNight,
  });

  final int playerCount;
  final VoidCallback onStartNight;

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
                    Icons.nights_stay,
                    size: _hiddenIconSize,
                    color: AppColors.nightAccent,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  const Text(
                    'Herkes rolünü öğrendi',
                    textAlign: TextAlign.center,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    '$playerCount kişilik köyde güneş batıyor. Telefonu '
                    'ortaya koyun; gece boyunca telefon sırayla HERKESİN '
                    'eline geçecek.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        AppButton(
          label: 'Geceyi Başlat',
          variant: ButtonVariant.night,
          fullWidth: true,
          onPressed: onStartNight,
        ),
      ],
    );
  }
}
