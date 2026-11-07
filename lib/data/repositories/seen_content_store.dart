import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/seen_content_tracker.dart';
import 'local_storage_repository.dart';

/// [SeenContentStore]'un cihaz deposu ([LocalStorageRepository]) uygulaması.
class LocalSeenContentStore implements SeenContentStore {
  const LocalSeenContentStore(this._repository);

  final LocalStorageRepository _repository;

  @override
  List<String> load() => _repository.loadSeenContent();

  @override
  Future<void> save(List<String> keys) => _repository.saveSeenContent(keys);
}

/// Tüm oyunların ortak "görülen içerik" hafızası (Imposter kelimeleri, Tabu
/// kartları, Tik Tak Bomba görevleri). Tek örnek: bellekteki küme uygulama
/// boyunca yaşar, her değişiklik cihaza yazılır.
final seenContentTrackerProvider = Provider<SeenContentTracker>((ref) {
  return SeenContentTracker(
    LocalSeenContentStore(ref.watch(localStorageRepositoryProvider)),
  );
});
