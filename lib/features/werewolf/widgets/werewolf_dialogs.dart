import 'package:flutter/widgets.dart';

import '../../../core/widgets/app_exit_dialog.dart';

/// "Oyundan çıkılsın mı?" onayı. Onaylanırsa `true` döner.
///
/// Tüm oyunlarla ortak Neon Ink onay penceresini kullanır.
Future<bool> confirmWerewolfExit(BuildContext context) =>
    confirmExitGame(context);
