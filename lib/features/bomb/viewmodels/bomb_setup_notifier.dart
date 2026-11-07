import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../data/repositories/bomb_task_repository.dart';
import '../../../data/repositories/local_storage_repository.dart';
import '../../../domain/models/bomb/bomb_settings.dart';
import '../../../domain/models/player.dart';
import 'bomb_setup_state.dart';

/// Tik Tak Bomba kurulumu: oyuncular ve oyun ayarları (fitil, tur, kategori).
///
/// Oyuncu isimleri tüm oyunlarla ortak geçmişe kaydedilir. Oyun ayarları
/// cihazda saklanır ([LocalStorageRepository.saveBombSettings]); kayıtlı değer
/// bozuksa ya da artık geçerli değilse (örn. kategori kaldırıldı) varsayılan
/// kullanılır.
class BombSetupNotifier extends Notifier<BombSetupState> {
  int _idCounter = 0;

  @override
  BombSetupState build() {
    return BombSetupState(
      history: _repository.loadPlayerHistory(),
      settings: _loadSettings(),
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
    if (name.length > BombSetupState.maxNameLength) {
      state = state.copyWith(
        inputError:
            'İsim en fazla ${BombSetupState.maxNameLength} karakter olabilir.',
      );
      return false;
    }
    if (!state.canAddPlayer) {
      state = state.copyWith(
        inputError: 'En fazla ${BombSettings.maxPlayers} oyuncu eklenebilir.',
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

  void setFuse(BombFuse fuse) =>
      _updateSettings(state.settings.copyWith(fuse: fuse));

  void setRounds(int rounds) {
    if (!BombSettings.roundOptions.contains(rounds)) return;
    _updateSettings(state.settings.copyWith(rounds: rounds));
  }

  /// `null` = Karışık.
  void setCategory(String? categoryId) {
    if (categoryId != null && !_categoryIds.contains(categoryId)) return;
    _updateSettings(
      categoryId == null
          ? state.settings.copyWith(clearCategory: true)
          : state.settings.copyWith(categoryId: categoryId),
    );
  }

  // --- Yardımcılar ---

  Iterable<String> get _categoryIds =>
      ref.read(bombTaskRepositoryProvider).categoryNames.keys;

  BombSettings _loadSettings() {
    final record = _repository.loadBombSettings();
    final rounds = record.rounds;
    final categoryId = record.categoryId;
    return BombSettings(
      fuse: BombFuse.fromName(record.fuse) ?? BombFuse.medium,
      rounds: rounds != null && BombSettings.roundOptions.contains(rounds)
          ? rounds
          : BombSettings.defaultRounds,
      categoryId: categoryId != null && _categoryIds.contains(categoryId)
          ? categoryId
          : null,
    );
  }

  void _updateSettings(BombSettings settings) {
    state = state.copyWith(settings: settings);
    _persist(
      _repository.saveBombSettings((
        fuse: settings.fuse.name,
        rounds: settings.rounds,
        categoryId: settings.categoryId,
      )),
    );
  }

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
        debugPrint('Tik Tak Bomba kaydı yapılamadı: $error');
        return null;
      }),
    );
  }

  String _generateId() =>
      'bomb_player_${_idCounter++}_${DateTime.now().microsecondsSinceEpoch}';
}

final bombSetupProvider = NotifierProvider<BombSetupNotifier, BombSetupState>(
  BombSetupNotifier.new,
);
