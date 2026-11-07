import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../data/repositories/local_storage_repository.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/werewolf/werewolf_role.dart';
import '../../../domain/models/werewolf/werewolf_settings.dart';
import 'werewolf_setup_state.dart';

/// Vampir Köylü kurulumunu yöneten Notifier: oyuncu listesi ve rol dağılımı.
///
/// - Otomatik denge açıkken her oyuncu ekleme/çıkarmada dağılım
///   [WerewolfSettings.recommended] ile yeniden hesaplanır.
/// - Kullanıcı vampir sayısını ya da özel rolleri elle değiştirirse
///   otomatik denge kapanır; tekrar açılırsa öneriye döner.
/// - Oyuncu isimleri tüm oyunlarla ortak geçmişe ([LocalStorageRepository])
///   kaydedilir; Imposter'da girilen isimler burada da önerilir.
class WerewolfSetupNotifier extends Notifier<WerewolfSetupState> {
  int _idCounter = 0;

  @override
  WerewolfSetupState build() {
    return WerewolfSetupState(
      history: _repository.loadPlayerHistory(),
      settings: WerewolfSettings.recommended(0),
    );
  }

  LocalStorageRepository get _repository =>
      ref.read(localStorageRepositoryProvider);

  HapticService get _haptics => ref.read(hapticServiceProvider);

  // --- Oyuncular ---

  /// Oyuncu ekler. Başarılıysa `true`, doğrulama hatasında `false` döner.
  bool addPlayer(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) {
      state = state.copyWith(inputError: 'İsim boş olamaz.');
      return false;
    }
    if (name.length > WerewolfSetupState.maxNameLength) {
      state = state.copyWith(
        inputError:
            'İsim en fazla ${WerewolfSetupState.maxNameLength} karakter olabilir.',
      );
      return false;
    }
    if (!state.canAddPlayer) {
      state = state.copyWith(
        inputError:
            'En fazla ${WerewolfSettings.maxPlayers} oyuncu eklenebilir.',
      );
      return false;
    }
    final key = name.toLowerTr();
    if (state.players.any((p) => p.name.toLowerTr() == key)) {
      state = state.copyWith(inputError: 'Bu isim zaten eklendi.');
      return false;
    }

    _setPlayers([...state.players, Player(id: _generateId(), name: name)]);
    state = state.copyWith(
      history: _mergeHistory([name], state.history),
      clearInputError: true,
    );
    _persist(_repository.rememberPlayers([name]));
    return true;
  }

  bool addFromHistory(String name) {
    final added = addPlayer(name);
    if (added) _haptics.selectionClick();
    return added;
  }

  void removePlayer(String id) {
    _setPlayers(state.players.where((p) => p.id != id).toList());
    state = state.copyWith(clearInputError: true);
  }

  void forgetFromHistory(String name) {
    final key = name.toLowerTr();
    state = state.copyWith(
      history: state.history.where((n) => n.toLowerTr() != key).toList(),
    );
    _persist(_repository.forgetPlayer(name));
  }

  /// Oyun başlarken kadroyu geçmişin başına taşır.
  void rememberCurrentPlayers() {
    final names = state.players.map((p) => p.name).toList();
    if (names.isEmpty) return;
    state = state.copyWith(history: _mergeHistory(names, state.history));
    _persist(_repository.rememberPlayers(names));
  }

  // --- Rol dağılımı ---

  void setAutoBalance(bool enabled) {
    state = state.copyWith(
      autoBalance: enabled,
      settings: enabled ? _recommended() : state.settings,
    );
  }

  /// Vampir sayısını [delta] kadar değiştirir (1 ile izin verilen en fazla
  /// sayı arasında tutulur).
  void changeVampireCount(int delta) {
    final max = state.maxVampires.clamp(1, WerewolfSettings.maxPlayers);
    final next = (state.settings.vampireCount + delta).clamp(1, max);
    if (next == state.settings.vampireCount) return;
    _haptics.selectionClick();
    _setManual(state.settings.copyWith(vampireCount: next));
  }

  void setDoctor(bool enabled) =>
      _setManual(state.settings.copyWith(includeDoctor: enabled));

  void setWitch(bool enabled) =>
      _setManual(state.settings.copyWith(includeWitch: enabled));

  void setSeer(bool enabled) =>
      _setManual(state.settings.copyWith(includeSeer: enabled));

  void setHunter(bool enabled) =>
      _setManual(state.settings.copyWith(includeHunter: enabled));

  void setTieBreak(WerewolfTieBreak tieBreak) {
    state = state.copyWith(
      settings: state.settings.copyWith(tieBreak: tieBreak),
    );
  }

  void setDiscussionSeconds(int seconds) {
    if (!WerewolfSettings.discussionOptions.contains(seconds)) return;
    state = state.copyWith(
      settings: state.settings.copyWith(discussionSeconds: seconds),
    );
  }

  void setRevealRoleOnDeath(bool enabled) {
    state = state.copyWith(
      settings: state.settings.copyWith(revealRoleOnDeath: enabled),
    );
  }

  // --- Yardımcılar ---

  void _setPlayers(List<Player> players) {
    state = state.copyWith(players: players);
    if (state.autoBalance) {
      state = state.copyWith(settings: _recommended());
    } else {
      // Elle ayarlanmış dağılımda bile vampir sayısı yeni oyuncu sayısının
      // izin verdiği üst sınırı aşamaz.
      final max = state.maxVampires.clamp(1, WerewolfSettings.maxPlayers);
      if (state.settings.vampireCount > max) {
        state = state.copyWith(
          settings: state.settings.copyWith(vampireCount: max),
        );
      }
    }
  }

  void _setManual(WerewolfSettings settings) {
    state = state.copyWith(settings: settings, autoBalance: false);
  }

  WerewolfSettings _recommended() => WerewolfSettings.recommended(
        state.playerCount,
        tieBreak: state.settings.tieBreak,
        discussionSeconds: state.settings.discussionSeconds,
        revealRoleOnDeath: state.settings.revealRoleOnDeath,
      );

  List<String> _mergeHistory(List<String> first, List<String> rest) {
    final seen = <String>{};
    final merged = <String>[];
    for (final name in [...first, ...rest]) {
      if (!seen.add(name.toLowerTr())) continue;
      merged.add(name);
      if (merged.length == LocalStorageRepository.maxPlayerHistory) break;
    }
    return merged;
  }

  void _persist(Future<Object?> write) {
    unawaited(
      write.catchError((Object error, StackTrace stackTrace) {
        debugPrint('Oyuncu geçmişi kaydedilemedi: $error');
        return null;
      }),
    );
  }

  String _generateId() =>
      'ww_player_${_idCounter++}_${DateTime.now().microsecondsSinceEpoch}';
}

final werewolfSetupProvider =
    NotifierProvider<WerewolfSetupNotifier, WerewolfSetupState>(
  WerewolfSetupNotifier.new,
);
