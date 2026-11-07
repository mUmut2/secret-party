import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/models/taboo_settings.dart';
import '../../settings/utils/settings_labels.dart';
import '../../help/how_to_play.dart';
import '../viewmodels/taboo_game_notifier.dart';
import '../viewmodels/taboo_setup_notifier.dart';
import '../viewmodels/taboo_setup_state.dart';
import '../widgets/taboo_option_selector.dart';
import '../widgets/taboo_scoreboard.dart';

const double _teamDotSize = 12;
const double _ruleIconSize = 18;

/// Tabu kurulum ekranı: takım isimleri, tur süresi, pas hakkı ve hedef skor.
///
/// `TextEditingController`'lar saf UI state'i olarak burada kalır; değerler
/// her değişimde [TabooSetupNotifier]'a iletilir, doğrulama orada yapılır.
class TabooSetupScreen extends ConsumerStatefulWidget {
  const TabooSetupScreen({super.key});

  @override
  ConsumerState<TabooSetupScreen> createState() => _TabooSetupScreenState();
}

class _TabooSetupScreenState extends ConsumerState<TabooSetupScreen> {
  late final TextEditingController _teamAController;
  late final TextEditingController _teamBController;

  @override
  void initState() {
    super.initState();
    // Ekrana geri dönüldüğünde önceki girişler korunur.
    final setup = ref.read(tabooSetupProvider);
    _teamAController = TextEditingController(text: setup.teamAInput);
    _teamBController = TextEditingController(text: setup.teamBInput);
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  void _startGame(TabooSetupState setup) {
    FocusScope.of(context).unfocus();
    ref.read(tabooGameProvider.notifier).startGame(setup.toSettings());
    context.go(AppRouter.tabooGame);
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(tabooSetupProvider);
    final notifier = ref.read(tabooSetupProvider.notifier);
    final error = setup.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabu'),
        actions: const [HowToPlayButton(guide: GameGuide.taboo)],
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
                    'Takımlarını kur, kuralları seç.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const _SectionTitle('Takımlar'),
                  const SizedBox(height: AppSpacing.s),
                  _TeamNameField(
                    controller: _teamAController,
                    hint: TabooSettings.defaultTeamAName,
                    color: tabooTeamColor(0),
                    onChanged: notifier.setTeamAName,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _TeamNameField(
                    controller: _teamBController,
                    hint: TabooSettings.defaultTeamBName,
                    color: tabooTeamColor(1),
                    onChanged: notifier.setTeamBName,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      error,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.l),
                  const _SectionTitle('Tur Süresi'),
                  const SizedBox(height: AppSpacing.s),
                  TabooOptionSelector(
                    semanticPrefix: 'Tur süresi',
                    options: TabooSettings.roundDurationOptions,
                    selected: setup.roundDurationSeconds,
                    labelOf: durationLabel,
                    onSelected: notifier.setRoundDuration,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const _SectionTitle('Tur Başına Pas Hakkı'),
                  const SizedBox(height: AppSpacing.s),
                  TabooOptionSelector(
                    semanticPrefix: 'Pas hakkı',
                    options: TabooSettings.passLimitOptions,
                    selected: setup.passLimit,
                    labelOf: (value) => value == 0 ? 'Yok' : '$value',
                    onSelected: notifier.setPassLimit,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const _SectionTitle('Hedef Skor'),
                  const SizedBox(height: AppSpacing.s),
                  TabooOptionSelector(
                    semanticPrefix: 'Hedef skor',
                    options: TabooSettings.targetScoreOptions,
                    selected: setup.targetScore,
                    labelOf: (value) => '$value',
                    onSelected: notifier.setTargetScore,
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
              child: AppButton(
                label: 'Oyuna Başla',
                variant: ButtonVariant.primary,
                fullWidth: true,
                onPressed: setup.canStart ? () => _startGame(setup) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.title);
  }
}

class _TeamNameField extends StatelessWidget {
  const _TeamNameField({
    required this.controller,
    required this.hint,
    required this.color,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: TabooSetupState.maxTeamNameLength,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium,
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: Center(
          widthFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Container(
              width: _teamDotSize,
              height: _teamDotSize,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide(color: color),
        ),
      ),
    );
  }
}

/// Kısa kural özeti: yeni oyuncular için tek bakışta anlaşılır.
class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nasıl Oynanır?', style: AppTypography.title),
          SizedBox(height: AppSpacing.s),
          _RuleRow(
            icon: Icons.record_voice_over,
            color: AppColors.textSecondary,
            text: 'Anlatıcı, yasaklı kelimeleri söylemeden kelimeyi anlatır.',
          ),
          _RuleRow(
            icon: Icons.check_circle,
            color: AppColors.primary,
            text: 'Doğru tahmin: +1 puan.',
          ),
          _RuleRow(
            icon: Icons.block,
            color: AppColors.error,
            text: 'Yasaklı kelime söylenirse TABU: −1 puan.',
          ),
          _RuleRow(
            icon: Icons.skip_next,
            color: AppColors.warning,
            text: 'Pas: puan değişmez, kart değişir.',
          ),
          _RuleRow(
            icon: Icons.emoji_events,
            color: AppColors.tertiary,
            text: 'İki takım eşit tur oynadığında hedefe ulaşan ve önde '
                'olan takım kazanır.',
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.color,
    required this.text,
  });

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
