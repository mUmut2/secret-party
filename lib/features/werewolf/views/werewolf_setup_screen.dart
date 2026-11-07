import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tap_target.dart';
import '../../../domain/models/werewolf/werewolf_role.dart';
import '../../../domain/models/werewolf/werewolf_settings.dart';
import '../../settings/widgets/duration_selector.dart';
import '../../help/how_to_play.dart';
import '../viewmodels/werewolf_game_notifier.dart';
import '../viewmodels/werewolf_setup_notifier.dart';
import '../viewmodels/werewolf_setup_state.dart';
import '../widgets/werewolf_role_style.dart';

const double _roleIconSize = 24;
const double _historyRowHeight = 40;
const double _chipIconSize = 16;
const double _stepperButtonSize = 40;

/// Vampir Köylü kurulum ekranı: oyuncular, rol dağılımı ve kurallar.
class WerewolfSetupScreen extends ConsumerStatefulWidget {
  const WerewolfSetupScreen({super.key});

  @override
  ConsumerState<WerewolfSetupScreen> createState() =>
      _WerewolfSetupScreenState();
}

class _WerewolfSetupScreenState extends ConsumerState<WerewolfSetupScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final added = ref
        .read(werewolfSetupProvider.notifier)
        .addPlayer(_nameController.text);
    if (added) _nameController.clear();
  }

  void _startGame(WerewolfSetupState setup) {
    FocusScope.of(context).unfocus();
    ref.read(werewolfSetupProvider.notifier).rememberCurrentPlayers();
    ref
        .read(werewolfGameProvider.notifier)
        .startGame(setup.players, setup.settings);
    context.go(AppRouter.werewolfReveal);
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(werewolfSetupProvider);
    final notifier = ref.read(werewolfSetupProvider.notifier);
    final setupError = setup.setupError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vampir Köylü'),
        actions: const [HowToPlayButton(guide: GameGuide.werewolf)],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Oyun seçimine dön',
          onPressed: () => context.go(AppRouter.gameSelection),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.l),
                children: [
                  const Text(
                    'Köyü kur, rolleri dağıt. Geceleri vampirler avlanır, '
                    'gündüzleri köy şüphelileri sürgün eder.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _SectionHeader(
                    title: 'Oyuncular',
                    trailing:
                        '${setup.playerCount}/${WerewolfSettings.maxPlayers}',
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _AddPlayerRow(
                    controller: _nameController,
                    enabled: setup.canAddPlayer,
                    onAdd: _addPlayer,
                  ),
                  if (setup.inputError != null) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      setup.inputError!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  AnimatedSize(
                    duration: AppMotion.base,
                    curve: AppMotion.standardCurve,
                    alignment: Alignment.topCenter,
                    child: setup.availableHistory.isEmpty
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.m),
                            child: _HistoryRow(
                              names: setup.availableHistory,
                              enabled: setup.canAddPlayer,
                              onSelect: notifier.addFromHistory,
                              onForget: notifier.forgetFromHistory,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (setup.players.isEmpty)
                    const Text(
                      'Henüz oyuncu eklenmedi.',
                      style: AppTypography.bodyMedium,
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        for (final player in setup.players)
                          _PlayerChip(
                            key: ValueKey(player.id),
                            name: player.name,
                            onRemove: () => notifier.removePlayer(player.id),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(title: 'Roller'),
                  const SizedBox(height: AppSpacing.s),
                  _AutoBalanceTile(
                    enabled: setup.autoBalance,
                    onChanged: notifier.setAutoBalance,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _WerewolfStepper(
                    count: setup.settings.vampireCount,
                    canDecrease: setup.settings.vampireCount > 1,
                    canIncrease:
                        setup.settings.vampireCount < setup.maxVampires,
                    onChanged: notifier.changeVampireCount,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _RoleToggleTile(
                    role: WerewolfRole.doktor,
                    value: setup.settings.includeDoctor,
                    onChanged: notifier.setDoctor,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _RoleToggleTile(
                    role: WerewolfRole.cadi,
                    value: setup.settings.includeWitch,
                    onChanged: notifier.setWitch,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _RoleToggleTile(
                    role: WerewolfRole.kahin,
                    value: setup.settings.includeSeer,
                    onChanged: notifier.setSeer,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _RoleToggleTile(
                    role: WerewolfRole.avci,
                    value: setup.settings.includeHunter,
                    onChanged: notifier.setHunter,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _RoleSummary(setup: setup),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(title: 'Oylamada Eşitlik Olursa'),
                  const SizedBox(height: AppSpacing.s),
                  _TieBreakSelector(
                    selected: setup.settings.tieBreak,
                    onSelected: notifier.setTieBreak,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(title: 'Gündüz Tartışma Süresi'),
                  const SizedBox(height: AppSpacing.s),
                  DurationSelector(
                    options: WerewolfSettings.discussionOptions,
                    selectedSeconds: setup.settings.discussionSeconds,
                    onSelected: notifier.setDiscussionSeconds,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _SwitchTile(
                    title: 'Ölenlerin rolü açıklansın',
                    subtitle: 'Kapalıysa roller oyun sonuna kadar gizli kalır.',
                    value: setup.settings.revealRoleOnDeath,
                    onChanged: notifier.setRevealRoleOnDeath,
                  ),
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
                  if (setupError != null) ...[
                    Text(
                      setupError,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                  ],
                  AppButton(
                    label: 'Rolleri Dağıt',
                    variant: ButtonVariant.primary,
                    fullWidth: true,
                    onPressed: setup.canStart ? () => _startGame(setup) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.title)),
        if (trailing != null) Text(trailing!, style: AppTypography.bodyMedium),
      ],
    );
  }
}

class _AddPlayerRow extends StatelessWidget {
  const _AddPlayerRow({
    required this.controller,
    required this.enabled,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: enabled ? 'Oyuncu adı' : 'Oyuncu sınırına ulaşıldı',
              hintStyle: AppTypography.bodyMedium,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(AppSpacing.m),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.m),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        AppButton(
          label: 'Ekle',
          variant: ButtonVariant.outlined,
          onPressed: enabled ? onAdd : null,
        ),
      ],
    );
  }
}

/// Geçmiş oyuncular (tüm oyunlarla ortak): dokun → ekle, çarpı → unut.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.names,
    required this.enabled,
    required this.onSelect,
    required this.onForget,
  });

  final List<String> names;
  final bool enabled;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onForget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history,
              size: _chipIconSize,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Geçmişten Seç',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          height: _historyRowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: names.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
            itemBuilder: (context, index) {
              final name = names[index];
              return Opacity(
                opacity: enabled ? 1 : 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        button: true,
                        label: '$name, oyuncu olarak ekle',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: enabled ? () => onSelect(name) : null,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.m,
                              right: AppSpacing.xs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(name, style: AppTypography.bodyLarge),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.add,
                                  size: _chipIconSize,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AppTapTarget(
                        semanticLabel: '$name, geçmişten sil',
                        onTap: () => onForget(name),
                        child: const Icon(
                          Icons.close,
                          size: _chipIconSize,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({super.key, required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: AppTypography.bodyLarge),
          AppTapTarget(
            semanticLabel: '$name, oyuncuyu sil',
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: _chipIconSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoBalanceTile extends StatelessWidget {
  const _AutoBalanceTile({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      title: 'Otomatik Dağılım',
      subtitle: enabled
          ? 'Roller oyuncu sayısına göre dengeleniyor.'
          : 'Roller elle ayarlandı. Açarsan öneriye döner.',
      value: enabled,
      onChanged: onChanged,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLarge),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.surfaceElevated,
          ),
        ],
      ),
    );
  }
}

class _WerewolfStepper extends StatelessWidget {
  const _WerewolfStepper({
    required this.count,
    required this.canDecrease,
    required this.canIncrease,
    required this.onChanged,
  });

  final int count;
  final bool canDecrease;
  final bool canIncrease;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const role = WerewolfRole.vampir;
    return AppCard(
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
                Text(role.label, style: AppTypography.bodyLarge),
                const Text('Vampir sayısı', style: AppTypography.caption),
              ],
            ),
          ),
          _StepperButton(
            icon: Icons.remove,
            tooltip: 'Vampir azalt',
            onPressed: canDecrease ? () => onChanged(-1) : null,
          ),
          SizedBox(
            width: _stepperButtonSize,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: role.color),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            tooltip: 'Vampir artır',
            onPressed: canIncrease ? () => onChanged(1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: AppColors.primary,
      disabledColor: AppColors.textDisabled,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceElevated,
        fixedSize: const Size.square(_stepperButtonSize),
      ),
    );
  }
}

class _RoleToggleTile extends StatelessWidget {
  const _RoleToggleTile({
    required this.role,
    required this.value,
    required this.onChanged,
  });

  final WerewolfRole role;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          Icon(
            role.icon,
            color: value ? role.color : AppColors.textDisabled,
            size: _roleIconSize,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.label, style: AppTypography.bodyLarge),
                Text(
                  role.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: role.color,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.surfaceElevated,
          ),
        ],
      ),
    );
  }
}

/// Dağılım özeti: hangi rolden kaç tane olacağı.
class _RoleSummary extends StatelessWidget {
  const _RoleSummary({required this.setup});

  final WerewolfSetupState setup;

  @override
  Widget build(BuildContext context) {
    final settings = setup.settings;
    final villagers = setup.villagerCount;
    final counts = <WerewolfRole, int>{
      WerewolfRole.vampir: settings.vampireCount,
      if (settings.includeDoctor) WerewolfRole.doktor: 1,
      if (settings.includeWitch) WerewolfRole.cadi: 1,
      if (settings.includeSeer) WerewolfRole.kahin: 1,
      if (settings.includeHunter) WerewolfRole.avci: 1,
      WerewolfRole.koylu: villagers < 0 ? 0 : villagers,
    };

    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final entry in counts.entries)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: entry.key.color),
            ),
            child: Text(
              '${entry.value} ${entry.key.label}',
              style: AppTypography.caption.copyWith(color: entry.key.color),
            ),
          ),
      ],
    );
  }
}

/// Eşitlik kuralı için iki segmentli seçici.
class _TieBreakSelector extends StatelessWidget {
  const _TieBreakSelector({required this.selected, required this.onSelected});

  final WerewolfTieBreak selected;
  final ValueChanged<WerewolfTieBreak> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Row(
        children: [
          for (final option in WerewolfTieBreak.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == selected,
                label: 'Eşitlikte: ${option.label}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(option),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standardCurve,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == selected
                          ? AppColors.primary
                          : AppColors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    child: Text(
                      option.label,
                      maxLines: 1,
                      style: AppTypography.label.copyWith(
                        color: option == selected
                            ? AppColors.onPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
