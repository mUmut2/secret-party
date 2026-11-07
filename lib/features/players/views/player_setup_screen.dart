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
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/player.dart';
import '../../../domain/services/game_engine_notifier.dart';
import '../../settings/viewmodels/game_settings_notifier.dart';
import '../../settings/widgets/settings_summary_card.dart';
import '../../help/how_to_play.dart';
import '../viewmodels/player_setup_notifier.dart';
import '../viewmodels/player_setup_state.dart';

const double _listAvatarSize = 40;
const double _historyAvatarSize = 24;
const double _historyRowHeight = 44;
const double _historyIconSize = 16;
const double _chipBorderWidth = 1;
const double _disabledChipOpacity = 0.4;

/// Oyuncuların isimlerini girdiği ve oyun ayarlarına ulaştığı kurulum ekranı.
///
/// `TextEditingController` gibi saf UI state'i burada kalır; oyuncu
/// ekleme/silme ve geçmiş kuralları [PlayerSetupNotifier]'da, oyun kurma
/// kuralları `GameEngine`'dedir. Bu ekran sadece ayarları okuyup motora iletir.
class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleAddPlayer() {
    final success =
        ref.read(playerSetupProvider.notifier).addPlayer(_nameController.text);
    // Hatalı girişte alan temizlenmez: kullanıcı düzeltip tekrar deneyebilsin.
    if (success) {
      _nameController.clear();
    }
  }

  void _handleStartGame(List<Player> players) {
    ref.read(playerSetupProvider.notifier).rememberCurrentPlayers();
    final settings = ref.read(gameSettingsProvider);
    ref.read(gameSessionProvider.notifier).startGame(
          players,
          categoryId: settings.selectedCategoryId,
          roundDurationSeconds: settings.roundDurationSeconds,
          giveImposterHint: settings.giveImposterHint,
        );
    context.go(AppRouter.roleReveal);
  }

  Future<void> _handleClearHistory() async {
    final approved = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (_) => const _ClearHistoryDialog(),
    );
    if (approved != true || !mounted) return;
    ref.read(playerSetupProvider.notifier).clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerSetupProvider);
    final notifier = ref.read(playerSetupProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyuncular'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Oyun seçimine dön',
          onPressed: () => context.go(AppRouter.gameSelection),
        ),
        actions: const [HowToPlayButton(guide: GameGuide.imposter)],
      ),
      // Tüm içerik tek kaydırılabilir listede: küçük ekranlarda ve büyük
      // sistem yazı boyutunda taşma olmaz. "Oyunu Başlat" her zaman altta.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.l,
                  AppSpacing.l,
                  AppSpacing.s,
                ),
                children: [
                  Text(
                    '${state.players.length}/${PlayerSetupState.maxPlayers} oyuncu',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _AddPlayerRow(
                    controller: _nameController,
                    enabled: state.canAddPlayer,
                    onAdd: _handleAddPlayer,
                  ),
                  // Geçmiş boşaldığında (tümü eklendi / silindi) bölüm yumuşakça
                  // kapanır; liste aşağı doğru zıplamaz.
                  AnimatedSize(
                    duration: AppMotion.base,
                    curve: AppMotion.standardCurve,
                    alignment: Alignment.topCenter,
                    child: state.hasAvailableHistory
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.m),
                            child: _HistorySection(
                              names: state.availableHistory,
                              enabled: state.canAddPlayer,
                              onSelect: notifier.addFromHistory,
                              onForget: notifier.forgetFromHistory,
                              onClearAll: _handleClearHistory,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      state.errorMessage!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  if (state.isBelowMinimum) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Oyuna başlamak için en az ${PlayerSetupState.minPlayers} oyuncu gerekiyor.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.m),
                  const SettingsSummaryCard(),
                  const SizedBox(height: AppSpacing.m),
                  if (state.players.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'Henüz oyuncu eklenmedi',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    )
                  else
                    for (final player in state.players) ...[
                      _PlayerListItem(
                        key: ValueKey(player.id),
                        player: player,
                        onRemove: () => notifier.removePlayer(player.id),
                      ),
                      const SizedBox(height: AppSpacing.s),
                    ],
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
                label: 'Oyunu Başlat',
                variant: ButtonVariant.primary,
                fullWidth: true,
                onPressed: state.canStartGame
                    ? () => _handleStartGame(state.players)
                    : null,
              ),
            ),
          ],
        ),
      ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.m,
              ),
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

/// "Geçmişten Seç": daha önce oynamış isimlerin yatay kaydırılabilen listesi.
///
/// Bir isme dokunmak onu anında aktif listeye ekler; sağdaki çarpı ise ismi
/// cihaz hafızasından siler. Liste sadece henüz eklenmemiş isimleri gösterir.
class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.names,
    required this.enabled,
    required this.onSelect,
    required this.onForget,
    required this.onClearAll,
  });

  final List<String> names;
  final bool enabled;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onForget;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history,
              size: _historyIconSize,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Geçmişten Seç',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            AppTapTarget(
              semanticLabel: 'Tüm oyuncu geçmişini temizle',
              onTap: onClearAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                child: Text(
                  'Temizle',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
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
              return _HistoryChip(
                key: ValueKey(name),
                name: name,
                enabled: enabled,
                onTap: () => onSelect(name),
                onForget: () => onForget(name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryChip extends StatefulWidget {
  const _HistoryChip({
    super.key,
    required this.name,
    required this.enabled,
    required this.onTap,
    required this.onForget,
  });

  final String name;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onForget;

  @override
  State<_HistoryChip> createState() => _HistoryChipState();
}

class _HistoryChipState extends State<_HistoryChip> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: widget.enabled ? 1.0 : _disabledChipOpacity,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standardCurve,
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: _isPressed ? AppColors.primary : AppColors.divider,
            width: _chipBorderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              enabled: widget.enabled,
              label: '${widget.name}, oyuncu olarak ekle',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                onTap: widget.enabled ? widget.onTap : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerAvatar(
                        name: widget.name,
                        size: _historyAvatarSize,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(widget.name, style: AppTypography.bodyLarge),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.add,
                        size: _historyIconSize,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppTapTarget(
              semanticLabel: '${widget.name}, geçmişten sil',
              onTap: widget.onForget,
              child: const Icon(
                Icons.close,
                size: _historyIconSize,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerListItem extends StatelessWidget {
  const _PlayerListItem({
    super.key,
    required this.player,
    required this.onRemove,
  });

  final Player player;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Yeni eklenen oyuncu kısa bir kayma + belirme ile listeye girer.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.standardCurve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * AppSpacing.s),
          child: child,
        ),
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            PlayerAvatar(name: player.name, size: _listAvatarSize),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                player.name,
                style: AppTypography.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              tooltip: 'Oyuncuyu sil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Tüm geçmişi silmeden önce gösterilen onay diyaloğu.
class _ClearHistoryDialog extends StatelessWidget {
  const _ClearHistoryDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Geçmiş temizlensin mi?',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Kayıtlı tüm oyuncu isimleri bu cihazdan silinecek. '
              'Şu anki oyuncu listesi etkilenmez.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: 'Evet, Temizle',
              variant: ButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.s),
            AppButton(
              label: 'Vazgeç',
              variant: ButtonVariant.ghost,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
