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
import '../../../data/repositories/bomb_task_repository.dart';
import '../../../domain/models/bomb/bomb_settings.dart';
import '../../help/how_to_play.dart';
import '../../settings/widgets/category_selector.dart';
import '../viewmodels/bomb_game_notifier.dart';
import '../viewmodels/bomb_setup_notifier.dart';
import '../viewmodels/bomb_setup_state.dart';
import '../widgets/bomb_option_selector.dart';

const double _historyRowHeight = 40;
const double _chipIconSize = 16;
const double _ruleIconSize = 18;
const double _disabledOpacity = 0.4;

/// Tik Tak Bomba kurulum ekranı: oyuncular, fitil, tur sayısı ve kategori.
class BombSetupScreen extends ConsumerStatefulWidget {
  const BombSetupScreen({super.key});

  @override
  ConsumerState<BombSetupScreen> createState() => _BombSetupScreenState();
}

class _BombSetupScreenState extends ConsumerState<BombSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final added =
        ref.read(bombSetupProvider.notifier).addPlayer(_nameController.text);
    if (added) {
      _nameController.clear();
      // Enter ile art arda ekleme: klavye açık kalır.
      _nameFocus.requestFocus();
    }
  }

  void _startGame(BombSetupState setup) {
    FocusScope.of(context).unfocus();
    ref.read(bombSetupProvider.notifier).rememberCurrentPlayers();
    ref
        .read(bombGameProvider.notifier)
        .startGame(setup.players, setup.settings);
    context.go(AppRouter.bombReady);
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(bombSetupProvider);
    final notifier = ref.read(bombSetupProvider.notifier);
    final setupError = setup.setupError;
    final categoryNames = ref.watch(bombTaskRepositoryProvider).categoryNames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tik Tak Bomba'),
        actions: const [HowToPlayButton(guide: GameGuide.bomb)],
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
                    'Görevi yüksek sesle cevapla, bombayı hemen sıradakine '
                    'geçir. Fitil gizli: patladığında bomba kimdeyse o yanar!',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _SectionHeader(
                    title: 'Oyuncular',
                    trailing: '${setup.playerCount}/${BombSettings.maxPlayers}',
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _AddPlayerRow(
                    controller: _nameController,
                    focusNode: _nameFocus,
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
                    duration: AppMotion.resolve(context, AppMotion.base),
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
                  const _SectionHeader(title: 'Fitil'),
                  const SizedBox(height: AppSpacing.s),
                  BombOptionSelector<BombFuse>(
                    options: BombFuse.values,
                    selected: setup.settings.fuse,
                    labelOf: (fuse) => fuse.label,
                    semanticPrefix: 'Fitil',
                    onSelected: notifier.setFuse,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Patlama anı her turda gizli ve rastgele.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(title: 'Tur Sayısı'),
                  const SizedBox(height: AppSpacing.s),
                  BombOptionSelector<int>(
                    options: BombSettings.roundOptions,
                    selected: setup.settings.rounds,
                    labelOf: (rounds) => '$rounds Tur',
                    onSelected: notifier.setRounds,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(title: 'Kategori'),
                  const SizedBox(height: AppSpacing.s),
                  CategorySelector(
                    categoryIds: categoryNames.keys.toList(),
                    selectedCategoryId: setup.settings.categoryId,
                    labelOf: (id) =>
                        id == null ? 'Karışık' : (categoryNames[id] ?? id),
                    onSelected: notifier.setCategory,
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
                    label: 'Bombayı Hazırla',
                    variant: ButtonVariant.warning,
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
    required this.focusNode,
    required this.enabled,
    required this.onAdd,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
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
                                  color: AppColors.warning,
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
          // Uzun isim dar ekranda çipi taşırmasın.
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLarge,
            ),
          ),
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
            icon: Icons.record_voice_over,
            color: AppColors.warning,
            text: 'Bomba sendeyse ekrandaki göreve uygun bir cevabı yüksek '
                'sesle söyle. Aynı turda söylenen cevap tekrar edilmez.',
          ),
          _RuleRow(
            icon: Icons.swipe_right,
            color: AppColors.primary,
            text: '"GEÇİR"e dokun ve telefonu hemen sıradaki oyuncuya ver.',
          ),
          _RuleRow(
            icon: Icons.local_fire_department,
            color: AppColors.error,
            text: 'Fitil bitince bomba kimdeyse o patlar. Turlar sonunda en '
                'az patlayan kazanır!',
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
