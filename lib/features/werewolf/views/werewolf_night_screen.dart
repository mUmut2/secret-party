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
import '../../../domain/services/werewolf_engine.dart';
import '../viewmodels/werewolf_game_notifier.dart';
import '../viewmodels/werewolf_pass_flow_notifier.dart';
import '../widgets/werewolf_dialogs.dart';
import '../widgets/werewolf_missing_game_view.dart';
import '../../../core/widgets/app_pass_gate.dart';
import '../widgets/werewolf_player_picker.dart';
import '../widgets/werewolf_role_style.dart';

const double _heroIconSize = 72;
const double _roleIconSize = 32;
const double _resultIconSize = 48;

/// Gece fazı: "Gece Oldu, Köy Uyuyor..." — sıralı tek telefon.
///
/// GİZLİLİK: Telefonu kimin aldığından rolü anlaşılmasın diye telefon
/// sırayla YAŞAYAN HER OYUNCUNUN eline geçer. Her oyuncu:
/// 1. KİLİTLİ ekranda adını görür, butonu basılı tutarak gizlice açar.
/// 2. Rolünü ve haklarını görür; hakkı varsa hamlesini yapar, yoksa
///    "Aksiyonun Yok / Hakkın Bitti" yazar.
/// 3. "Devam Et" ile telefonu sıradakine verir; ekran yeniden kilitlenir.
/// Herkes bitirince "Sabahı Getir" ile gecenin sonucu hesaplanır.
class WerewolfNightScreen extends ConsumerWidget {
  const WerewolfNightScreen({super.key});

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
    final current = game.currentTurnPlayer;

    final Widget body;
    final String bodyKey;
    if (game.phase != WerewolfPhase.nightPhase) {
      // Sabaha geçiş animasyonu sürerken gösterilir.
      bodyKey = 'dawn';
      body = const _DawnView();
    } else if (!flow.introSeen && game.turnIndex == 0) {
      bodyKey = 'intro';
      body = _NightIntro(
        dayNumber: game.dayNumber,
        playerCount: game.turnOrder.length,
        onBegin: flowNotifier.dismissIntro,
      );
    } else if (current == null) {
      bodyKey = 'end';
      body = _NightEnd(
        onMorning: () {
          ref.read(werewolfGameProvider.notifier).resolveNight();
          context.go(AppRouter.werewolfDay);
        },
      );
    } else if (!flow.isUnlocked(game.turnIndex)) {
      bodyKey = 'gate_${game.turnIndex}';
      body = AppPassGate(
        playerName: current.name,
        instruction: 'telefonu al ve gizlice ekranı aç.',
        accentColor: AppColors.nightAccent,
        progressLabel: '${game.turnIndex + 1}/${game.turnOrder.length}',
        onUnlocked: () => flowNotifier.unlock(game),
      );
    } else {
      bodyKey = 'turn_${game.turnIndex}';
      body = _TurnPanel(game: game, player: current);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit(context, ref);
      },
      child: Scaffold(
        backgroundColor: AppColors.nightBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NightTopBar(
                  dayNumber: game.dayNumber,
                  onExit: () => _requestExit(context, ref),
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

class _NightTopBar extends StatelessWidget {
  const _NightTopBar({required this.dayNumber, required this.onExit});

  final int dayNumber;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onExit,
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          tooltip: 'Oyundan çık',
        ),
        const Spacer(),
        const Icon(Icons.nights_stay, color: AppColors.nightAccent),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$dayNumber. GECE',
          style: AppTypography.label.copyWith(color: AppColors.nightAccent),
        ),
      ],
    );
  }
}

/// Ortak düzen: ortada içerik, altta tek buton.
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

class _NightIntro extends StatelessWidget {
  const _NightIntro({
    required this.dayNumber,
    required this.playerCount,
    required this.onBegin,
  });

  final int dayNumber;
  final int playerCount;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return _CenteredStep(
      button: AppButton(
        label: 'Gece Başlasın',
        variant: ButtonVariant.night,
        fullWidth: true,
        onPressed: onBegin,
      ),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: AppMotion.resolve(context, AppMotion.dramatic),
          curve: AppMotion.dramaticCurve,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: const Icon(
            Icons.nights_stay,
            size: _heroIconSize,
            color: AppColors.nightAccent,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          'Gece Oldu,\nKöy Uyuyor...',
          textAlign: TextAlign.center,
          style: AppTypography.display.copyWith(
            shadows: [
              Shadow(
                color: AppShadows.glow(AppColors.nightAccent, 0.6),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          'Telefon sırayla yaşayan $playerCount kişinin de eline geçecek. '
          'Sıran gelince telefonu al, kimseye göstermeden ekranı aç, işini '
          'bitir ve telefonu sıradakine ver.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.s),
        const Text(
          'Kimin özel rolü olduğu anlaşılmasın diye herkes ekranda biraz '
          'zaman geçirsin.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

/// Sırası gelen oyuncunun gizli paneli: rolü, hakları ve hamlesi.
class _TurnPanel extends ConsumerWidget {
  const _TurnPanel({required this.game, required this.player});

  final WerewolfGameState game;
  final WerewolfPlayer player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(werewolfEngineProvider);
    final ability = engine.nightAbilityOf(game, player);
    final next = game.nextTurnPlayer;
    final continueLabel = next == null
        ? 'Devam Et, Geceyi Bitir'
        : 'Devam Et, Telefonu ${next.name.withDativeSuffix()} Ver';
    final onContinue =
        ref.read(werewolfGameProvider.notifier).completeNightTurn;

    final Widget content;
    switch (ability) {
      case WerewolfNightAbility.vampireHunt:
        content = _VampireAction(
          game: game,
          player: player,
          continueLabel: continueLabel,
          onContinue: onContinue,
        );
      case WerewolfNightAbility.doctorProtect:
        content = _DoctorAction(
          game: game,
          continueLabel: continueLabel,
          onContinue: onContinue,
        );
      case WerewolfNightAbility.witchPotions:
        content = _WitchAction(
          game: game,
          player: player,
          continueLabel: continueLabel,
          onContinue: onContinue,
        );
      case WerewolfNightAbility.seerInspect:
        content = _SeerAction(
          game: game,
          player: player,
          continueLabel: continueLabel,
          onContinue: onContinue,
        );
      case WerewolfNightAbility.hunterStandby:
        content = _InfoOnly(
          icon: Icons.gps_fixed,
          title: game.hunterBulletAvailable
              ? 'Kurşunun Hazır'
              : 'Kurşunun Kalmadı',
          message: 'Gece yapman gereken bir şey yok. Elendiğin an tek '
              'kurşununla bir kişiyi yanında götürüp götürmeyeceğine '
              'karar vereceksin.',
          continueLabel: continueLabel,
          onContinue: onContinue,
        );
      case WerewolfNightAbility.none:
        final exhausted = player.role != WerewolfRole.koylu;
        content = _InfoOnly(
          icon: exhausted ? Icons.hourglass_empty : Icons.bedtime,
          title: exhausted ? 'Hakkın Bitti' : 'Aksiyonun Yok',
          message: exhausted
              ? 'Bu oyundaki özel hakkını kullandın. Bu gece yapacağın '
                  'bir şey kalmadı.'
              : 'Köylüler gece uyur. Kimse şüphelenmesin diye birkaç saniye '
                  'bekle, sonra telefonu sıradakine ver.',
          continueLabel: continueLabel,
          onContinue: onContinue,
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoleHeader(player: player, rights: _rightsText(game, player)),
        const SizedBox(height: AppSpacing.m),
        Expanded(child: content),
      ],
    );
  }

  /// Oyuncunun kalan haklarının kısa özeti.
  String _rightsText(WerewolfGameState game, WerewolfPlayer player) {
    switch (player.role) {
      case WerewolfRole.vampir:
        return 'Her gece bir av seçebilirsin.';
      case WerewolfRole.doktor:
        return 'Her gece bir kişiyi koruyabilirsin.';
      case WerewolfRole.cadi:
        return 'İyileştirme: ${game.witchHealAvailable ? 'VAR' : 'YOK'} · '
            'Zehir: ${game.witchPoisonAvailable ? 'VAR' : 'YOK'}';
      case WerewolfRole.kahin:
        return game.seerAvailable
            ? 'Tek sorgu hakkın duruyor.'
            : 'Sorgu hakkını kullandın.';
      case WerewolfRole.avci:
        return game.hunterBulletAvailable
            ? '1 kurşunun var.'
            : 'Kurşunun kalmadı.';
      case WerewolfRole.koylu:
        return 'Özel hakkın yok.';
    }
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({required this.player, required this.rights});

  final WerewolfPlayer player;
  final String rights;

  @override
  Widget build(BuildContext context) {
    final role = player.role;
    return AppCard(
      variant: CardVariant.night,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          Icon(role.icon, size: _roleIconSize, color: role.color),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.name} · ${role.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: role.color),
                ),
                Text(rights, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hamle ekranlarının ortak iskeleti: başlık, içerik, alt buton.
class _ActionLayout extends StatelessWidget {
  const _ActionLayout({
    required this.title,
    required this.instruction,
    required this.content,
    required this.button,
  });

  final String title;
  final String instruction;
  final Widget content;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    // Başlık ve yönerge de kaydırılabilir alanda: küçük ekranlarda ve büyük
    // sistem yazı boyutunda yalnızca alttaki buton sabit kalır.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(instruction, style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.m),
                content,
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        button,
      ],
    );
  }
}

AppButton _continueButton(String label, VoidCallback onContinue) => AppButton(
      label: label,
      variant: ButtonVariant.night,
      fullWidth: true,
      onPressed: onContinue,
    );

/// Hamle kaydedildikten sonra gösterilen onay.
class _DoneNote extends StatelessWidget {
  const _DoneNote({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.night,
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(text, style: AppTypography.bodyLarge)),
        ],
      ),
    );
  }
}

class _VampireAction extends ConsumerStatefulWidget {
  const _VampireAction({
    required this.game,
    required this.player,
    required this.continueLabel,
    required this.onContinue,
  });

  final WerewolfGameState game;
  final WerewolfPlayer player;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  ConsumerState<_VampireAction> createState() => _VampireActionState();
}

class _VampireActionState extends ConsumerState<_VampireAction> {
  String? _targetId;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final myVote = game.nightActions.vampireVotes[widget.player.id];
    const role = WerewolfRole.vampir;

    // Diğer vampirlerin bu gece şimdiye kadarki seçimleri.
    final packVotes = game.nightActions.vampireVotes.entries
        .where((e) => e.key != widget.player.id)
        .map((e) => '${game.playerById(e.key).name} → '
            '${game.playerById(e.value).name}')
        .toList();
    final otherVampires = game.aliveVampires
        .where((p) => p.id != widget.player.id)
        .map((p) => p.name)
        .toList();

    if (myVote != null) {
      return _ActionLayout(
        title: 'Avın seçildi',
        instruction: 'Vampirlerin en çok seçtiği kişi bu gece saldırıya uğrar.',
        content: _DoneNote(
          text: 'Seçimin: ${game.playerById(myVote).name}',
          color: role.color,
        ),
        button: _continueButton(widget.continueLabel, widget.onContinue),
      );
    }

    return _ActionLayout(
      title: 'Bu gece kimi avlıyorsun?',
      instruction: otherVampires.isEmpty
          ? 'Tek vampir sensin; seçimin kesin av olur.'
          : 'Diğer vampirler: ${otherVampires.join(', ')}. '
              '${packVotes.isEmpty ? 'Henüz seçim yapmadılar.' : 'Seçimleri: ${packVotes.join(' · ')}'}',
      content: WerewolfPlayerPicker(
        players: ref.read(werewolfEngineProvider).vampireTargetOptions(game),
        selectedId: _targetId,
        accentColor: role.color,
        surfaceColor: AppColors.nightSurface,
        semanticAction: 'avla',
        onSelected: (id) => setState(() => _targetId = id),
      ),
      button: AppButton(
        label: 'Avı Onayla',
        variant: ButtonVariant.danger,
        fullWidth: true,
        haptics: false,
        onPressed: _targetId == null
            ? null
            : () =>
                ref.read(werewolfGameProvider.notifier).vampireVote(_targetId!),
      ),
    );
  }
}

class _DoctorAction extends ConsumerStatefulWidget {
  const _DoctorAction({
    required this.game,
    required this.continueLabel,
    required this.onContinue,
  });

  final WerewolfGameState game;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  ConsumerState<_DoctorAction> createState() => _DoctorActionState();
}

class _DoctorActionState extends ConsumerState<_DoctorAction> {
  String? _targetId;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final protectedId = game.nightActions.doctorProtectedId;
    final lastProtected = game.tryPlayerById(game.lastDoctorProtectedId);
    const role = WerewolfRole.doktor;

    if (protectedId != null) {
      return _ActionLayout(
        title: 'Koruman hazır',
        instruction: 'Vampirler bu kişiye saldırırsa kurtulacak.',
        content: _DoneNote(
          text: 'Koruduğun kişi: ${game.playerById(protectedId).name}',
          color: role.color,
        ),
        button: _continueButton(widget.continueLabel, widget.onContinue),
      );
    }

    return _ActionLayout(
      title: 'Bu gece kimi koruyorsun?',
      instruction: lastProtected == null
          ? 'Kendini de koruyabilirsin.'
          : 'Dün gece ${lastProtected.name} kişisini korudun; bu gece onu '
              'koruyamazsın.',
      content: WerewolfPlayerPicker(
        players: ref.read(werewolfEngineProvider).doctorOptions(game),
        selectedId: _targetId,
        accentColor: role.color,
        surfaceColor: AppColors.nightSurface,
        semanticAction: 'koru',
        onSelected: (id) => setState(() => _targetId = id),
      ),
      button: AppButton(
        label: 'Korumayı Onayla',
        variant: ButtonVariant.night,
        fullWidth: true,
        haptics: false,
        onPressed: _targetId == null
            ? null
            : () => ref
                .read(werewolfGameProvider.notifier)
                .doctorProtect(_targetId!),
      ),
    );
  }
}

class _WitchAction extends ConsumerStatefulWidget {
  const _WitchAction({
    required this.game,
    required this.player,
    required this.continueLabel,
    required this.onContinue,
  });

  final WerewolfGameState game;
  final WerewolfPlayer player;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  ConsumerState<_WitchAction> createState() => _WitchActionState();
}

class _WitchActionState extends ConsumerState<_WitchAction> {
  String? _healId;
  String? _poisonId;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final engine = ref.read(werewolfEngineProvider);
    const role = WerewolfRole.cadi;

    if (_done) {
      final heal = game.tryPlayerById(game.nightActions.witchHealTargetId);
      final poison = game.tryPlayerById(game.nightActions.witchPoisonTargetId);
      final summary = [
        if (heal != null) 'İyileştirdiğin: ${heal.name}',
        if (poison != null) 'Zehirlediğin: ${poison.name}',
        if (heal == null && poison == null) 'Bu gece iksir kullanmadın.',
      ].join('\n');
      return _ActionLayout(
        title: 'Kararın kaydedildi',
        instruction: 'İksirlerin gecenin sonunda etki eder.',
        content: _DoneNote(text: summary, color: role.color),
        button: _continueButton(widget.continueLabel, widget.onContinue),
      );
    }

    // Vampirler cadıdan önce oynadıysa, şu ana kadarki hedeflerini görür.
    final votes = game.nightActions.vampireVotes.values.toList();
    final String victimInfo;
    if (votes.isEmpty) {
      victimInfo = 'Vampirler henüz av seçmedi.';
    } else {
      final counts = <String, int>{};
      for (final id in votes) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
      final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      victimInfo =
          'Vampirlerin şu anki hedefi: ${game.playerById(top.key).name}.';
    }

    return _ActionLayout(
      title: 'İksirlerini kullanacak mısın?',
      instruction: '$victimInfo Her iksir oyunda yalnızca bir kez kullanılır.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PotionTitle(
            icon: Icons.healing,
            title: 'İyileştirme İksiri',
            available: game.witchHealAvailable,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.s),
          if (game.witchHealAvailable)
            WerewolfPlayerPicker(
              players: engine.witchHealOptions(game),
              selectedId: _healId,
              accentColor: AppColors.success,
              surfaceColor: AppColors.nightSurface,
              noneOptionLabel: 'Kimseyi iyileştirme',
              semanticAction: 'iyileştir',
              onSelected: (id) => setState(() => _healId = id),
            ),
          const SizedBox(height: AppSpacing.l),
          _PotionTitle(
            icon: Icons.science,
            title: 'Zehir İksiri',
            available: game.witchPoisonAvailable,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.s),
          if (game.witchPoisonAvailable)
            WerewolfPlayerPicker(
              players: engine.witchPoisonOptions(game, widget.player.id),
              selectedId: _poisonId,
              accentColor: AppColors.error,
              surfaceColor: AppColors.nightSurface,
              noneOptionLabel: 'Kimseyi zehirleme',
              semanticAction: 'zehirle',
              onSelected: (id) => setState(() => _poisonId = id),
            ),
        ],
      ),
      button: AppButton(
        label: 'Kararı Onayla',
        variant: ButtonVariant.night,
        fullWidth: true,
        haptics: false,
        onPressed: () {
          ref.read(werewolfGameProvider.notifier).witchAct(
                healTargetId: _healId,
                poisonTargetId: _poisonId,
              );
          setState(() => _done = true);
        },
      ),
    );
  }
}

class _PotionTitle extends StatelessWidget {
  const _PotionTitle({
    required this.icon,
    required this.title,
    required this.available,
    required this.color,
  });

  final IconData icon;
  final String title;
  final bool available;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: available ? color : AppColors.textDisabled),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            available ? title : '$title (kullanıldı)',
            style: AppTypography.title.copyWith(
              color: available ? AppColors.textPrimary : AppColors.textDisabled,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeerAction extends ConsumerStatefulWidget {
  const _SeerAction({
    required this.game,
    required this.player,
    required this.continueLabel,
    required this.onContinue,
  });

  final WerewolfGameState game;
  final WerewolfPlayer player;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  ConsumerState<_SeerAction> createState() => _SeerActionState();
}

class _SeerActionState extends ConsumerState<_SeerAction> {
  String? _targetId;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final inspected = game.tryPlayerById(game.nightActions.seerInspectedId);
    const role = WerewolfRole.kahin;

    if (inspected != null) {
      final inspectedRole = inspected.role;
      return _ActionLayout(
        title: 'Kehanet gerçekleşti',
        instruction: 'Bu bilgiyi sadece sen biliyorsun. Hakkın artık bitti.',
        content: AppCard(
          variant: CardVariant.night,
          child: Column(
            children: [
              Icon(
                inspectedRole.icon,
                size: _resultIconSize,
                color: inspectedRole.color,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                inspected.name,
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'bir ${inspectedRole.label.toUpperTr()}',
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(
                  color: inspectedRole.color,
                ),
              ),
            ],
          ),
        ),
        button: _continueButton(widget.continueLabel, widget.onContinue),
      );
    }

    return _ActionLayout(
      title: 'Kimin rolünü sorgulayacaksın?',
      instruction: 'Oyun boyunca TEK sorgu hakkın var. İstersen bu gece '
          'kullanmayıp saklayabilirsin.',
      content: WerewolfPlayerPicker(
        players: ref
            .read(werewolfEngineProvider)
            .seerOptions(game, widget.player.id),
        selectedId: _targetId,
        accentColor: role.color,
        surfaceColor: AppColors.nightSurface,
        semanticAction: 'sorgula',
        onSelected: (id) => setState(() => _targetId = id),
      ),
      button: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Rolünü Sorgula',
            variant: ButtonVariant.night,
            fullWidth: true,
            haptics: false,
            onPressed: _targetId == null
                ? null
                : () => ref
                    .read(werewolfGameProvider.notifier)
                    .seerInspect(_targetId!),
          ),
          const SizedBox(height: AppSpacing.s),
          AppButton(
            label: 'Hakkımı Sakla, Devam Et',
            variant: ButtonVariant.ghost,
            fullWidth: true,
            onPressed: widget.onContinue,
          ),
        ],
      ),
    );
  }
}

/// Hamlesi olmayan sıra: köylü, hakkı bitmiş rol ya da avcı.
class _InfoOnly extends StatelessWidget {
  const _InfoOnly({
    required this.icon,
    required this.title,
    required this.message,
    required this.continueLabel,
    required this.onContinue,
  });

  final IconData icon;
  final String title;
  final String message;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _CenteredStep(
      button: _continueButton(continueLabel, onContinue),
      children: [
        Icon(icon, size: _heroIconSize, color: AppColors.nightSecondary),
        const SizedBox(height: AppSpacing.m),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.display,
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}

class _NightEnd extends StatelessWidget {
  const _NightEnd({required this.onMorning});

  final VoidCallback onMorning;

  @override
  Widget build(BuildContext context) {
    return _CenteredStep(
      button: AppButton(
        label: 'Sabahı Getir',
        variant: ButtonVariant.warning,
        fullWidth: true,
        onPressed: onMorning,
      ),
      children: const [
        Icon(
          Icons.bedtime,
          size: _heroIconSize,
          color: AppColors.nightSecondary,
        ),
        SizedBox(height: AppSpacing.m),
        Text(
          'Gece Sona Erdi',
          textAlign: TextAlign.center,
          style: AppTypography.display,
        ),
        SizedBox(height: AppSpacing.m),
        Text(
          'Telefon herkesin elinden geçti. Telefonu ortaya koyun; ufukta ilk '
          'ışıklar beliriyor. Bakalım bu gece köyde neler oldu...',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}

class _DawnView extends StatelessWidget {
  const _DawnView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.wb_twilight,
        size: _heroIconSize,
        color: AppColors.warning,
      ),
    );
  }
}
