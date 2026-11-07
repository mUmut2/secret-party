import 'dart:io';

import 'app_id.dart';

/// Uygulama kimliğini Android ve iOS'ta tek seferde değiştirir.
///
/// Kullanım (proje kökünde):
///   dart run tool/set_app_id.dart com.adsoyad.secretparty
///
/// Değiştirilenler:
/// - android/app/build.gradle.kts → namespace + applicationId
/// - MainActivity.kt → package satırı ve klasörü (yeni pakete taşınır)
/// - ios/Runner.xcodeproj/project.pbxproj → PRODUCT_BUNDLE_IDENTIFIER
///   (Runner ve RunnerTests)
///
/// DİKKAT: Mağazaya ilk yüklemeden sonra kimlik DEĞİŞTİRİLEMEZ.
void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
        'Kullanım: dart run tool/set_app_id.dart com.adsoyad.secretparty');
    exitCode = 64;
    return;
  }
  final id = args.single.trim();
  final error = validateAppId(id);
  if (error != null) {
    stderr.writeln(error);
    exitCode = 65;
    return;
  }

  final gradle = File('android/app/build.gradle.kts');
  gradle.writeAsStringSync(replaceGradleIds(gradle.readAsStringSync(), id));

  final kotlinRoot = Directory('android/app/src/main/kotlin');
  final activity = kotlinRoot
      .listSync(recursive: true)
      .whereType<File>()
      .firstWhere((f) => f.path.endsWith('MainActivity.kt'));
  final target = File(
    [kotlinRoot.path, ...id.split('.'), 'MainActivity.kt'].join('/'),
  );
  final source = replaceKotlinPackage(activity.readAsStringSync(), id);
  if (activity.absolute.path != target.absolute.path) {
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(source);
    activity.deleteSync();
    _deleteEmptyParents(activity.parent, stopAt: kotlinRoot);
  } else {
    activity.writeAsStringSync(source);
  }

  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  pbxproj.writeAsStringSync(replaceBundleIds(pbxproj.readAsStringSync(), id));

  stdout.writeln('Kimlik güncellendi: $id');
  stdout.writeln('Kontrol: flutter clean && flutter analyze && flutter test');
}

void _deleteEmptyParents(Directory dir, {required Directory stopAt}) {
  var current = dir;
  while (current.absolute.path != stopAt.absolute.path &&
      current.listSync().isEmpty) {
    final parent = current.parent;
    current.deleteSync();
    current = parent;
  }
}
