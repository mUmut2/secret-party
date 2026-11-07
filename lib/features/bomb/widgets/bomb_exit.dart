import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_exit_dialog.dart';
import '../viewmodels/bomb_game_notifier.dart';

/// Oyundan çıkış: ortak onay penceresi; onaylanırsa fitil durur, oyun silinir
/// ve oyun seçimine dönülür. Pencere açıkken fitil DURAKLATILIR (tartışma
/// sırasında bomba patlamasın), vazgeçilirse kaldığı yerden devam eder.
Future<void> requestBombExit(BuildContext context, WidgetRef ref) async {
  final game = ref.read(bombGameProvider.notifier)..pause();
  final approved = await confirmExitGame(context);
  if (!approved) {
    game.resume();
    return;
  }
  game.quit();
  if (context.mounted) context.go(AppRouter.gameSelection);
}

/// Bomba ekranlarının ortak sarmalayıcısı: geri tuşu çıkış onayı sorar.
class BombExitScope extends ConsumerWidget {
  const BombExitScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) requestBombExit(context, ref);
      },
      child: child,
    );
  }
}

/// Üst satırdaki "Oyundan çık" butonu.
class BombExitButton extends ConsumerWidget {
  const BombExitButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => requestBombExit(context, ref),
      icon: const Icon(Icons.close, color: AppColors.textSecondary),
      tooltip: 'Oyundan çık',
    );
  }
}
