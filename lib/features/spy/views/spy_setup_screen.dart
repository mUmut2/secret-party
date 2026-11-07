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
import '../../../data/repositories/spy_location_repository.dart';
import '../../../domain/models/spy/spy_settings.dart';
import '../../settings/widgets/duration_selector.dart';
import '../../help/how_to_play.dart';
import '../viewmodels/spy_game_notifier.dart';
import '../viewmodels/spy_setup_notifier.dart';
import '../viewmodels/spy_setup_state.dart';
import '../widgets/spy_locations_sheet.dart';

const double _historyRowHeight = 40;
const double _chipIconSize = 16;
const double _ruleIconSize = 18;
const double _disabledOpacity = 0.4;

/// Ajan kurulum ekranı: oyuncular, ajan sayısı, tur süresi ve
/// "Muhtemel Konumlar" rehberi.
class SpySetupScreen extends ConsumerStatefulWidget {
  const SpySetupScreen({super.key});

  @override
  ConsumerState<SpySetupScreen> createState() => _SpySetupScreenState();
}

class _SpySetupScreenState extends ConsumerState<SpySetupScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final added =
        ref.read(spySetupProvider.notifier).addPlayer(_nameController.text);
    if (added) _nameController.clear();
  }

  void _startGame(SpySetupState setup) {
    FocusScope.of(context).unfocus();
    ref.read(spySetupProvider.notifier).rememberCurrentPlayers();
    ref.read(spyGameProvider.notifier).startGame(setup.players, setup.settings);
    context.go(AppRouter.spyReveal);
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(spySetupProvider);
    final notifier = ref.read(spySetupProvider.notifier);
    final setupError = setup.setupError;
    final locations = ref.watch(spyLocationRepositoryProvider).locations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajan'),
        actions: const [HowToPlayButton(guide: GameGuide.spy)],
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
                    'Herkes gizli konumu biliyor, ajan hariç. Sorularla ajanı '
                    'bulun; ajan da konumu çözmeye çalışsın.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _SectionHeader(
                    title: 'Oyuncular',
                    trailing: '${setup.playerCount}/${SpySettings.maxPlayers}',
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
                  const _SectionHeader(title: 'Ajan Sayısı'),
                  const SizedBox(height: AppSpacing.s),
                  _SpyCountSelector(
                    selected: setup.settings.spyCount,
                    twoSpiesEnabled: setup.canHaveTwoSpies,
                    onSelected: notifier.setSpyCount,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    setup.canHaveTwoSpies
                        ? 'İki ajan birbirini bilmez ama aynı takımdadır.'
                        : 'İki ajan için en az '
                            '${SpySettings.minPlayersForTwoSpies} oyuncu gerekir.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(title: 'Tur Süresi'),
                  const SizedBox(height: AppSpacing.s),
                  DurationSelector(
                    options: SpySettings.discussionOptions,
                    selectedSeconds: setup.settings.discussionSeconds,
                    onSelected: notifier.setDiscussionSeconds,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Muhtemel Konumlar (${locations.length})',
                    variant: ButtonVariant.outlined,
                    fullWidth: true,
                    onPressed: () => showSpyLocationsSheet(
                      context,
                      locations: locations,
                      showRoles: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const _RulesCard(),
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
                opacity: enabled ? 1 : _disabledOpacity,
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

/// 1 / 2 ajan seçici. 2 ajan, yeterli oyuncu yoksa pasiftir.
class _SpyCountSelector extends StatelessWidget {
  const _SpyCountSelector({
    required this.selected,
    required this.twoSpiesEnabled,
    required this.onSelected,
  });

  final int selected;
  final bool twoSpiesEnabled;
  final ValueChanged<int> onSelected;

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
          for (final count in SpySettings.spyCountOptions)
            Expanded(
              child: Opacity(
                opacity: count == 2 && !twoSpiesEnabled ? _disabledOpacity : 1,
                child: Semantics(
                  button: true,
                  selected: count == selected,
                  enabled: count == 1 || twoSpiesEnabled,
                  label: '$count ajan',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(count),
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.standardCurve,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: count == selected
                            ? AppColors.secondary
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.m),
                      ),
                      child: Text(
                        '$count AJAN',
                        style: AppTypography.label.copyWith(
                          color: count == selected
                              ? AppColors.onPrimary
                              : AppColors.textSecondary,
                        ),
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

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nasıl Oynanır?', style: AppTypography.title),
          _RuleRow(
            icon: Icons.question_answer,
            color: AppColors.primary,
            text: 'Sırayla birbirinize konumla ilgili sorular sorun. Fazla '
                'açık vermeyin; ajan dinliyor!',
          ),
          _RuleRow(
            icon: Icons.policy,
            color: AppColors.secondary,
            text: 'Ajan istediği an oyunu durdurup konumu tahmin edebilir. '
                'Doğruysa ajan, yanlışsa masumlar kazanır.',
          ),
          _RuleRow(
            icon: Icons.how_to_vote,
            color: AppColors.warning,
            text: 'Oylamada masum biri suçlanırsa ya da oylar eşitse ajan '
                'kazanır. Ajan yakalanırsa son bir tahmin hakkı olur.',
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: _ruleIconSize, color: color),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
