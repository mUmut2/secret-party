import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/widgets/app_exit_dialog.dart';
import '../../../domain/services/game_engine_notifier.dart';
import '../viewmodels/round_notifier.dart';

/// Imposter oyun ekranlarından çıkış: onay sorulur, tur sayacı durdurulur,
/// oturum kapatılır ve Oyun Seçimi'ne dönülür.
Future<void> requestImposterExit(BuildContext context, WidgetRef ref) async {
  final approved = await confirmExitGame(context);
  if (!approved || !context.mounted) return;
  ref.read(roundProvider.notifier).stop();
  ref.read(gameSessionProvider.notifier).endSession();
  context.go(AppRouter.gameSelection);
}

/// Imposter oyun ekranlarını saran geri tuşu koruması: geri tuşu oyunu
/// kapatmaz, çıkış onayı sorar.
class ImposterExitGuard extends ConsumerWidget {
  const ImposterExitGuard({super.key, required this.child, this.onBack});

  final Widget child;

  /// Onay penceresi açılmadan ÖNCE çalışır (örn. açık rol kartını kapatmak;
  /// gizli bilgi pencerenin arkasında görünmesin).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onBack?.call();
        requestImposterExit(context, ref);
      },
      child: child,
    );
  }
}
