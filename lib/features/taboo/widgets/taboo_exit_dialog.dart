import 'package:flutter/widgets.dart';

import '../../../core/widgets/app_exit_dialog.dart';

/// "Oyundan çıkılsın mı?" onayı. Onaylanırsa `true` döner.
///
/// Skorlar kalıcı tutulmadığı için çıkış geri alınamaz; yanlışlıkla geri
/// tuşuna basılmasına karşı her çıkışta sorulur. Tüm oyunlarla ortak Neon Ink
/// onay penceresini kullanır.
Future<bool> confirmTabooExit(BuildContext context) => confirmExitGame(context);
