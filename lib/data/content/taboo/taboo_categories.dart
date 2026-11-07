import 'doga.dart';
import 'eglence.dart';
import 'genel.dart';
import 'mekan.dart';
import 'meslek.dart';
import 'spor.dart';
import 'taboo_deck.dart';
import 'teknoloji.dart';
import 'yiyecek.dart';

/// Kategori id → ekranda gösterilen Türkçe ad (gösterim sırasıyla).
const Map<String, String> tabooCategoryNames = {
  'genel': 'Genel',
  'yiyecek': 'Yiyecek & İçecek',
  'spor': 'Spor & Oyun',
  'eglence': 'Sinema & Müzik',
  'mekan': 'Mekânlar',
  'meslek': 'Meslekler',
  'teknoloji': 'Teknoloji',
  'doga': 'Doğa & Hayvanlar',
};

/// Kategori id → kartlar.
const Map<String, TabooCategoryDeck> tabooDecks = {
  'genel': genelDeck,
  'yiyecek': yiyecekDeck,
  'spor': sporDeck,
  'eglence': eglenceDeck,
  'mekan': mekanDeck,
  'meslek': meslekDeck,
  'teknoloji': teknolojiDeck,
  'doga': dogaDeck,
};
