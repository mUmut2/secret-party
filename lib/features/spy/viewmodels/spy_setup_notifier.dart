import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../data/repositories/local_storage_repository.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/spy/spy_settings.dart';
import 'spy_setup_state.dart';

/// Ajan kurulumunu yöneten Notifier: oyuncular, ajan sayısı, tur süresi.
///
/// Oyuncu isimleri tüm oyunlarla ortak geçmişe ([LocalStorageRepository])
/// kaydedilir; diğer oyunlarda girilen isimler burada da önerilir.
/// Oyuncu sayısı iki ajana yetmeyecek kadar düşerse ajan sayısı
/// kendiliğinden 1'e iner.
class SpySetupNotifier extends Notifier<SpySetupState> {
  int _idCounter = 0;

  @override
  SpySetupState build() {
    return SpySetupState(history: _repository.loadPlayerHistory());
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
    if (name.length > SpySetupState.maxNameLength) {
      state = state.copyWith(
        inputError:
            'İsim en fazla ${SpySetupState.maxNameLength} karakter olabilir.',
      );
      return false;
    }
    if (!state.canAddPlayer) {
      state = state.copyWith(
        inputError: 'En fazla ${SpySettings.maxPlayers} oyuncu eklenebilir.',
      );
      return false;
    }
    final key = name.toLowerTr();
    if (state.players.any((p) => p.name.toLowerTr() == key)) {
      state = state.copyWith(inputError: 'Bu isim zaten eklendi.');
      return false;
    }

    state = state.copyWith(
      players: [...state.players, Player(id: _generateId(), name: name)],
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
    state = state.copyWith(
      players: state.players.where((p) => p.id != id).toList(),
      clearInputError: true,
    );
    if (state.settings.spyCount > 1 && !state.canHaveTwoSpies) {
      state = state.copyWith(settings: state.settings.copyWith(spyCount: 1));
    }
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

  // --- Ayarlar ---

  void setSpyCount(int count) {
    if (!SpySettings.spyCountOptions.contains(count)) return;
    if (count == 2 && !state.canHaveTwoSpies) return;
    state = state.copyWith(settings: state.settings.copyWith(spyCount: count));
  }

  void setDiscussionSeconds(int seconds) {
    if (!SpySettings.discussionOptions.contains(seconds)) return;
    state = state.copyWith(
      settings: state.settings.copyWith(discussionSeconds: seconds),
    );
  }

  // --- Yardımcılar ---

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
      'spy_player_${_idCounter++}_${DateTime.now().microsecondsSinceEpoch}';
}

final spySetupProvider = NotifierProvider<SpySetupNotifier, SpySetupState>(
  SpySetupNotifier.new,
);
