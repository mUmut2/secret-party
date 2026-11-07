import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../data/repositories/local_storage_repository.dart';
import '../../../domain/models/player.dart';
import 'player_setup_state.dart';

/// Player Setup'ın TÜM iş mantığını (ekleme, silme, doğrulama, oyuncu
/// geçmişi) barındırır.
///
/// Oyuncu geçmişi [LocalStorageRepository] üzerinden cihazda saklanır:
/// - Açılışta geçmiş senkron okunur, "Geçmişten Seç" ilk karede hazırdır.
/// - Eklenen her isim geçmişin en başına taşınır (en yeni en önde).
/// - Kayıt arka planda yapılır; arayüz diske yazmayı beklemez.
class PlayerSetupNotifier extends Notifier<PlayerSetupState> {
  static const int _maxNameLength = 20;

  int _idCounter = 0;

  @override
  PlayerSetupState build() {
    return PlayerSetupState(history: _repository.loadPlayerHistory());
  }

  LocalStorageRepository get _repository =>
      ref.read(localStorageRepositoryProvider);

  HapticService get _haptics => ref.read(hapticServiceProvider);

  /// Yeni oyuncu ekler. Başarılıysa `true`, doğrulama hatasında `false` döner.
  bool addPlayer(String rawName) {
    final name = rawName.trim();

    if (name.isEmpty) {
      state = state.copyWith(errorMessage: 'İsim boş olamaz.');
      return false;
    }

    if (name.length > _maxNameLength) {
      state = state.copyWith(
        errorMessage: 'İsim en fazla $_maxNameLength karakter olabilir.',
      );
      return false;
    }

    if (!state.canAddPlayer) {
      state = state.copyWith(
        errorMessage:
            'En fazla ${PlayerSetupState.maxPlayers} oyuncu eklenebilir.',
      );
      return false;
    }

    final normalizedName = name.toLowerTr();
    final isDuplicate = state.players.any(
      (p) => p.name.toLowerTr() == normalizedName,
    );
    if (isDuplicate) {
      state = state.copyWith(errorMessage: 'Bu isim zaten eklendi.');
      return false;
    }

    final newPlayer = Player(id: _generateId(), name: name);
    state = state.copyWith(
      players: [...state.players, newPlayer],
      history: _historyWithFirst(name),
      clearError: true,
    );
    _persist(_repository.rememberPlayers([name]));
    return true;
  }

  /// "Geçmişten Seç" listesindeki bir isme dokunuldu: oyuncu anında aktif
  /// listeye eklenir. Doğrulama kuralları [addPlayer] ile aynıdır.
  bool addFromHistory(String name) {
    final added = addPlayer(name);
    if (added) {
      _haptics.selectionClick();
    }
    return added;
  }

  void removePlayer(String id) {
    state = state.copyWith(
      players: state.players.where((p) => p.id != id).toList(),
      clearError: true,
    );
  }

  /// İsmi cihazdaki oyuncu geçmişinden kalıcı olarak siler. Aktif listedeki
  /// oyunculara dokunmaz.
  void forgetFromHistory(String name) {
    final key = name.toLowerTr();
    state = state.copyWith(
      history: state.history.where((n) => n.toLowerTr() != key).toList(),
    );
    _persist(_repository.forgetPlayer(name));
  }

  /// Tüm oyuncu geçmişini cihazdan siler.
  void clearHistory() {
    state = state.copyWith(history: const []);
    _persist(_repository.clearPlayerHistory());
  }

  /// Oyun başlarken çağrılır: bu oyunun kadrosunu, ekleme sırasıyla
  /// geçmişin en başına taşır. Böylece bir sonraki açılışta aynı ekip
  /// "Geçmişten Seç" listesinin başında hazır bekler.
  void rememberCurrentPlayers() {
    final names = state.players.map((p) => p.name).toList();
    if (names.isEmpty) return;
    state = state.copyWith(
      history: _mergeHistory(names, state.history),
    );
    _persist(_repository.rememberPlayers(names));
  }

  /// [name]'i geçmişin en başına taşınmış haliyle döndürür (bellekteki kopya;
  /// diskteki kayıt [LocalStorageRepository] tarafından aynı kuralla yapılır).
  List<String> _historyWithFirst(String name) =>
      _mergeHistory([name], state.history);

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

  /// Disk yazmalarını arayüzü bekletmeden çalıştırır. Yazma başarısız olursa
  /// oyun etkilenmez: bellekteki liste doğru kalır, yalnızca bir sonraki
  /// açılışta geçmiş eksik olabilir.
  void _persist(Future<Object?> write) {
    unawaited(
      write.catchError((Object error, StackTrace stackTrace) {
        debugPrint('Oyuncu geçmişi kaydedilemedi: $error');
        return null;
      }),
    );
  }

  String _generateId() =>
      'player_${_idCounter++}_${DateTime.now().microsecondsSinceEpoch}';
}

final playerSetupProvider =
    NotifierProvider<PlayerSetupNotifier, PlayerSetupState>(
  PlayerSetupNotifier.new,
);
