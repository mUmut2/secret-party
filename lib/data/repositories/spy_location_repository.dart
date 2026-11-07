import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/spy/spy_location.dart';

/// Ajan konumlarına erişimin TEK soyutlaması.
///
/// Oyun motoru konumların nereden geldiğini (local / ileride JSON asset ya da
/// uzak sunucu) bilmez.
abstract class SpyLocationRepository {
  /// Oyunda çıkabilecek tüm konumlar (ekranda gösterim sırasıyla).
  List<SpyLocation> get locations;
}

/// MVP için in-memory konum listesi. Her konumda 8 rol vardır.
class LocalSpyLocationRepository implements SpyLocationRepository {
  const LocalSpyLocationRepository();

  static const List<SpyLocation> _locations = [
    SpyLocation(
      name: 'Korsan Gemisi',
      roles: [
        'Kaptan',
        'Tayfa',
        'Aşçı',
        'Tutsak',
        'Gözcü',
        'Topçu',
        'Dümenci',
        'Papağan Bakıcısı',
      ],
    ),
    SpyLocation(
      name: 'Uçak',
      roles: [
        'Pilot',
        'Yardımcı Pilot',
        'Kabin Memuru',
        'Cam Kenarı Yolcusu',
        'Bebekli Yolcu',
        'İş İnsanı',
        'Hava Polisi',
        'Uçmaktan Korkan Yolcu',
      ],
    ),
    SpyLocation(
      name: 'Hastane',
      roles: [
        'Cerrah',
        'Hemşire',
        'Hasta',
        'Ziyaretçi',
        'Anestezi Uzmanı',
        'Stajyer Doktor',
        'Temizlik Görevlisi',
        'Eczacı',
      ],
    ),
    SpyLocation(
      name: 'Denizaltı',
      roles: [
        'Kaptan',
        'Sonar Operatörü',
        'Makine Mühendisi',
        'Aşçı',
        'Torpido Uzmanı',
        'Telsizci',
        'Dalgıç',
        'Çaylak Denizci',
      ],
    ),
    SpyLocation(
      name: 'Otel',
      roles: [
        'Resepsiyonist',
        'Kat Görevlisi',
        'Bavul Taşıyıcı',
        'Otel Müdürü',
        'Balayı Çifti',
        'Şef',
        'Güvenlik Görevlisi',
        'Turist',
      ],
    ),
    SpyLocation(
      name: 'Lunapark',
      roles: [
        'Bilet Satıcısı',
        'Pamuk Şekerci',
        'Palyaço',
        'Çocuk',
        'Tamirci',
        'Dönme Dolap Görevlisi',
        'Fotoğrafçı',
        'Çocuğunu Kaybeden Ebeveyn',
      ],
    ),
    SpyLocation(
      name: 'Uzay İstasyonu',
      roles: [
        'Komutan',
        'Astronot',
        'Bilim İnsanı',
        'Mühendis',
        'Doktor',
        'Uzay Turisti',
        'Robot Bakımcısı',
        'Kargo Pilotu',
      ],
    ),
    SpyLocation(
      name: 'Okul',
      roles: [
        'Müdür',
        'Matematik Öğretmeni',
        'Öğrenci',
        'Hademe',
        'Kantinci',
        'Rehber Öğretmen',
        'Veli',
        'Beden Eğitimi Öğretmeni',
      ],
    ),
    SpyLocation(
      name: 'Tren',
      roles: [
        'Makinist',
        'Kondüktör',
        'Yolcu',
        'Yemekli Vagon Garsonu',
        'Bavul Hırsızı',
        'Sırt Çantalı Gezgin',
        'Yataklı Vagon Görevlisi',
        'Gazete Okuyan Amca',
      ],
    ),
    SpyLocation(
      name: 'Tiyatro',
      roles: [
        'Başrol Oyuncusu',
        'Yönetmen',
        'Suflör',
        'Seyirci',
        'Dekorcu',
        'Işıkçı',
        'Kostümcü',
        'Eleştirmen',
      ],
    ),
    SpyLocation(
      name: 'Polis Karakolu',
      roles: [
        'Komiser',
        'Dedektif',
        'Şüpheli',
        'Avukat',
        'Gazeteci',
        'Nöbetçi Memur',
        'Tanık',
        'Adli Tıp Uzmanı',
      ],
    ),
    SpyLocation(
      name: 'Restoran',
      roles: [
        'Şef',
        'Garson',
        'Müşteri',
        'Bulaşıkçı',
        'Şarap Uzmanı',
        'Kasiyer',
        'Yemek Eleştirmeni',
        'Komi',
      ],
    ),
    SpyLocation(
      name: 'Banka',
      roles: [
        'Veznedar',
        'Şube Müdürü',
        'Güvenlik Görevlisi',
        'Müşteri',
        'Soyguncu',
        'Kredi Danışmanı',
        'Temizlikçi',
        'Emekli Amca',
      ],
    ),
    SpyLocation(
      name: 'Plaj',
      roles: [
        'Cankurtaran',
        'Dondurmacı',
        'Turist',
        'Sörfçü',
        'Fotoğrafçı',
        'Çocuk',
        'Şezlong Kiralayan',
        'Kumdan Kale Ustası',
      ],
    ),
    SpyLocation(
      name: 'Sirk',
      roles: [
        'Palyaço',
        'Akrobat',
        'Hokkabaz',
        'Aslan Terbiyecisi',
        'Sihirbaz',
        'Seyirci',
        'Cambaz',
        'Sunucu',
      ],
    ),
    SpyLocation(
      name: 'Futbol Stadyumu',
      roles: [
        'Futbolcu',
        'Hakem',
        'Teknik Direktör',
        'Taraftar',
        'Simitçi',
        'Spiker',
        'Kaleci',
        'Saha Görevlisi',
      ],
    ),
    SpyLocation(
      name: 'Düğün Salonu',
      roles: [
        'Gelin',
        'Damat',
        'Nikah Memuru',
        'Davetli',
        'Fotoğrafçı',
        'Orkestra Şefi',
        'Garson',
        'Kayınvalide',
      ],
    ),
    SpyLocation(
      name: 'Askeri Üs',
      roles: [
        'Komutan',
        'Er',
        'Askeri Doktor',
        'Aşçı',
        'Tankçı',
        'Keskin Nişancı',
        'Nöbetçi',
        'Telsiz Operatörü',
      ],
    ),
    SpyLocation(
      name: 'Kapalıçarşı',
      roles: [
        'Kuyumcu',
        'Halıcı',
        'Turist',
        'Çaycı',
        'Antikacı',
        'Hamal',
        'Pazarlıkçı Müşteri',
        'Tur Rehberi',
      ],
    ),
    SpyLocation(
      name: 'Film Seti',
      roles: [
        'Yönetmen',
        'Başrol Oyuncusu',
        'Dublör',
        'Kameraman',
        'Makyöz',
        'Figüran',
        'Senarist',
        'Yapımcı',
      ],
    ),
    SpyLocation(
      name: 'Kayak Merkezi',
      roles: [
        'Kayak Hocası',
        'Snowboardçu',
        'Teleferik Görevlisi',
        'Turist',
        'Kafe Sahibi',
        'Kurtarma Ekibi',
        'Acemi Kayakçı',
        'Otel Görevlisi',
      ],
    ),
    SpyLocation(
      name: 'Hamam',
      roles: [
        'Tellak',
        'Natır',
        'Müşteri',
        'Kasiyer',
        'Turist',
        'Kese Ustası',
        'Çaycı',
        'Masör',
      ],
    ),
    SpyLocation(
      name: 'Antik Kazı Alanı',
      roles: [
        'Arkeolog',
        'Arkeoloji Öğrencisi',
        'Bekçi',
        'Turist',
        'Rehber',
        'Fotoğrafçı',
        'Restoratör',
        'Define Avcısı',
      ],
    ),
    SpyLocation(
      name: 'Süpermarket',
      roles: [
        'Kasiyer',
        'Reyon Görevlisi',
        'Market Müdürü',
        'Müşteri',
        'Kasap',
        'Fırıncı',
        'Güvenlik Görevlisi',
        'Kurye',
      ],
    ),
  ];

  @override
  List<SpyLocation> get locations => _locations;
}

final spyLocationRepositoryProvider = Provider<SpyLocationRepository>((ref) {
  return const LocalSpyLocationRepository();
});
