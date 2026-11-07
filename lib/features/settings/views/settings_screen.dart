import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_info.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/app_preferences_notifier.dart';
import '../../../core/services/link_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/local_storage_repository.dart';
import '../../../data/repositories/seen_content_store.dart';
import '../../help/how_to_play.dart';
import '../../players/viewmodels/player_setup_notifier.dart';
import '../../spy/viewmodels/spy_setup_notifier.dart';
import '../../werewolf/viewmodels/werewolf_setup_notifier.dart';

const double _tileIconSize = 22;

/// Uygulama ayarları: titreşim / ses tercihleri, oyun rehberleri, destek,
/// gizlilik ve sürüm bilgisi.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Platformun mağaza sayfası; henüz tanımlı değilse boş.
  String _storeUrl(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return isApple ? AppInfo.appStoreUrl : AppInfo.playStoreUrl;
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final approved = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Oyuncu geçmişi silinsin mi?',
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: AppSpacing.s),
              const Text(
                'Bu cihazda kayıtlı tüm oyuncu isimleri ve daha önce '
                'oynanan kelime/kart geçmişi kalıcı olarak silinecek. Bu '
                'işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.l),
              AppButton(
                label: 'Evet, Sil',
                variant: ButtonVariant.danger,
                fullWidth: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: AppSpacing.s),
              AppButton(
                label: 'Vazgeç',
                variant: ButtonVariant.ghost,
                fullWidth: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    if (approved != true) return;

    await ref.read(localStorageRepositoryProvider).clearPlayerHistory();
    // Tekrar önleme hafızası (görülen kelime / kart / görevler) da silinir.
    ref.read(seenContentTrackerProvider).clear();
    // Kurulum ekranları geçmişi bellekte de tuttuğu için yeniden yüklenir.
    ref
      ..invalidate(playerSetupProvider)
      ..invalidate(werewolfSetupProvider)
      ..invalidate(spySetupProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Oyuncu ve içerik geçmişi silindi.',
          style: AppTypography.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final prefsNotifier = ref.read(appPreferencesProvider.notifier);
    final storeUrl = _storeUrl(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Ana menüye dön',
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            const _SectionTitle('Tercihler'),
            _SwitchTile(
              icon: Icons.vibration,
              title: 'Titreşim',
              subtitle: 'Butonlarda, rol açılırken ve süre bitince '
                  'dokunsal geri bildirim.',
              value: prefs.hapticsEnabled,
              onChanged: prefsNotifier.setHapticsEnabled,
            ),
            const SizedBox(height: AppSpacing.s),
            _SwitchTile(
              icon: Icons.volume_up,
              title: 'Ses Efektleri',
              subtitle: 'Dokunma sesi ve süre bitti uyarısı.',
              value: prefs.soundEnabled,
              onChanged: prefsNotifier.setSoundEnabled,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Nasıl Oynanır?'),
            for (final guide in GameGuide.values) ...[
              _LinkTile(
                icon: guide.icon,
                iconColor: guide.color,
                title: guide.title,
                subtitle: guide.tagline,
                onTap: () => showHowToPlaySheet(context, guide),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            const SizedBox(height: AppSpacing.l),
            // Bağlantı değerleri (bkz. AppInfo) doldurulmadan satırlar
            // gösterilmez: kullanıcıya çalışmayan buton gösterilmez.
            if (storeUrl.isNotEmpty || AppInfo.supportEmail.isNotEmpty) ...[
              const _SectionTitle('Destek'),
              if (storeUrl.isNotEmpty) ...[
                _LinkTile(
                  icon: Icons.star_rate_rounded,
                  iconColor: AppColors.warning,
                  title: 'Uygulamayı Değerlendir',
                  subtitle: 'Beğendiysen mağazada puan vererek destek ol.',
                  onTap: () => LinkService.open(context, storeUrl),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              if (AppInfo.supportEmail.isNotEmpty) ...[
                _LinkTile(
                  icon: Icons.mail_outline,
                  iconColor: AppColors.tertiary,
                  title: 'Geri Bildirim / İletişim',
                  subtitle:
                      'Öneri, hata bildirimi ya da yeni oyun fikri gönder.',
                  onTap: () => LinkService.email(
                    context,
                    address: AppInfo.supportEmail,
                    subject: '${AppInfo.appName} Geri Bildirim',
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              const SizedBox(height: AppSpacing.l),
            ],
            const _SectionTitle('Gizlilik ve Veriler'),
            _LinkTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: AppColors.primary,
              title: 'Gizlilik Politikası',
              subtitle: 'Kişisel veri toplamıyoruz.',
              onTap: () => context.go(AppRouter.privacyPolicy),
            ),
            const SizedBox(height: AppSpacing.s),
            _LinkTile(
              icon: Icons.delete_outline,
              iconColor: AppColors.error,
              title: 'Oyuncu Geçmişini Sil',
              subtitle: 'Kayıtlı oyuncu isimlerini ve oynanan kelime/kart '
                  'geçmişini temizle.',
              onTap: () => _clearHistory(context, ref),
            ),
            const SizedBox(height: AppSpacing.s),
            _LinkTile(
              icon: Icons.description_outlined,
              iconColor: AppColors.textSecondary,
              title: 'Açık Kaynak Lisansları',
              subtitle: 'Kullanılan kütüphanelerin lisansları.',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.appName,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Hakkında'),
            const _LegalNotice(),
            const SizedBox(height: AppSpacing.xl),
            const _VersionInfo(),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(text, style: AppTypography.title),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
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
          Icon(
            icon,
            size: _tileIconSize,
            color: value ? AppColors.primary : AppColors.textDisabled,
          ),
          const SizedBox(width: AppSpacing.m),
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

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Icon(icon, size: _tileIconSize, color: iconColor),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyLarge),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oyun içeriğinde geçen özel adlarla ilgili yasal not.
class _LegalNotice extends StatelessWidget {
  const _LegalNotice();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: _tileIconSize,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              'Oyunlarda geçen film, dizi, ünlü ve marka adları yalnızca oyun '
              'içeriği olarak anılır ve ilgili hak sahiplerine aittir. '
              '${AppInfo.appName} bu kişi, kurum ve markalarla bağlantılı '
              'değildir; onlar tarafından desteklenmemekte veya '
              'onaylanmamaktadır.',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uygulama adı ve sürüm bilgisi (platformdan okunur).
class _VersionInfo extends StatelessWidget {
  const _VersionInfo();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version =
            info == null ? '' : 'Sürüm ${info.version} (${info.buildNumber})';
        return Column(
          children: [
            const Text(
              AppInfo.appName,
              textAlign: TextAlign.center,
              style: AppTypography.label,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              version,
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Arkadaşlarınla tek telefondan oyna. ❤',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
        );
      },
    );
  }
}
