import 'dart:convert';

import 'package:party_game/core/config/app_info.dart';
import 'package:party_game/features/settings/data/privacy_policy_content.dart';

/// `docs/gizlilik-politikasi.html` içeriğini uygulama içi metinden
/// ([PrivacyPolicyContent]) üretir. Böylece web ve uygulama metni birebir
/// aynı kalır.
///
/// Yeniden üretmek için: `dart run tool/generate_privacy_html.dart`
String renderPrivacyPolicyHtml() {
  const escape = HtmlEscape(HtmlEscapeMode.element);
  final buffer = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="tr">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    )
    ..writeln('<meta name="color-scheme" content="dark">')
    ..writeln(
      '<title>${escape.convert(AppInfo.appName)} · '
      '${escape.convert(PrivacyPolicyContent.title)}</title>',
    )
    ..writeln('<style>')
    ..writeln(_css)
    ..writeln('</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<main>')
    ..writeln('<p class="app">${escape.convert(AppInfo.appName)}</p>')
    ..writeln('<h1>${escape.convert(PrivacyPolicyContent.title)}</h1>')
    ..writeln(
      '<p class="summary">${escape.convert(PrivacyPolicyContent.summary)}</p>',
    )
    ..writeln(
      '<p class="date">'
      '${escape.convert(PrivacyPolicyContent.lastUpdatedLine)}</p>',
    );
  for (final section in PrivacyPolicyContent.sections) {
    buffer
      ..writeln('<section>')
      ..writeln('<h2>${escape.convert(section.title)}</h2>')
      ..writeln('<p>${escape.convert(section.body)}</p>')
      ..writeln('</section>');
  }
  buffer
    ..writeln('</main>')
    ..writeln('</body>')
    ..writeln('</html>');
  return buffer.toString();
}

/// Neon Ink koyu teması (web sayfası için; değerler AppColors ile aynıdır).
const String _css = '''
:root { --bg: #0B0B12; --surface: #17171F; --text: #F5F5FA;
  --muted: #9A9AB0; --lime: #B5E352; --divider: #2A2A38; }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
  font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
  "Helvetica Neue", Arial, sans-serif; }
main { max-width: 680px; margin: 0 auto; padding: 32px 16px 64px; }
.app { margin: 0; color: var(--lime); font-weight: 700; letter-spacing: 1px;
  text-transform: uppercase; font-size: 13px; }
h1 { margin: 4px 0 16px; font-size: 32px; line-height: 1.2; }
h2 { margin: 0 0 8px; font-size: 18px; }
.summary { background: var(--surface); border: 1.5px solid var(--lime);
  border-radius: 16px; padding: 16px; margin: 0 0 8px; }
.date { color: var(--muted); font-size: 13px; margin: 0 0 24px; }
section { border-top: 1px solid var(--divider); padding: 20px 0 4px; }
section p { color: var(--muted); margin: 0 0 12px; }''';
