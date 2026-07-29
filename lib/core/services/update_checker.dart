import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A newer release available on GitHub.
class UpdateInfo {
  const UpdateInfo({required this.tag, required this.url, this.highlights});

  /// Release tag, e.g. `v1.1.0`.
  final String tag;

  /// Web page of the release (assets + notes).
  final String url;

  /// First lines of the release notes, for the dialog.
  final String? highlights;
}

/// Checks LunarStack's GitHub Releases for a version newer than the installed
/// one. Fully silent on any failure (offline, rate limit, parse) — an update
/// prompt is a courtesy, never an error surface. Only for the sideload (GitHub
/// APK) build; the Play build never calls [check].
class UpdateChecker {
  static const _repo = 'AmaroMiranda/lunar-stack';
  static const _endpoint =
      'https://api.github.com/repos/$_repo/releases/latest';

  /// Returns the newer release, or null when up to date / on any failure.
  /// A release dismissed by the user (see [dismiss]) is not offered again.
  static Future<UpdateInfo?> check() async {
    try {
      final current = _parse((await PackageInfo.fromPlatform()).version);
      if (current == null) return null;

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      String body;
      try {
        final req = await client.getUrl(Uri.parse(_endpoint));
        req.headers.set(HttpHeaders.userAgentHeader, 'LunarStack-app');
        req.headers
            .set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
        final res = await req.close().timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) return null;
        body = await res
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 10));
      } finally {
        client.close(force: true);
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final latest = _parse(tag);
      final url = (json['html_url'] as String?) ??
          'https://github.com/$_repo/releases/latest';
      if (latest == null || !_newer(latest, current)) return null;
      if (await _isDismissed(tag)) return null;

      String? highlights;
      final notes = (json['body'] as String?)?.trim();
      if (notes != null && notes.isNotEmpty) {
        highlights = notes
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && !l.startsWith('#'))
            .take(4)
            .join('\n');
      }
      return UpdateInfo(tag: tag, url: url, highlights: highlights);
    } catch (_) {
      return null;
    }
  }

  /// Remember that the user declined [tag]; [check] skips it from now on.
  static Future<void> dismiss(String tag) async {
    try {
      (await _dismissFile()).writeAsStringSync(tag);
    } catch (_) {
      // Best effort — worst case the prompt shows again next launch.
    }
  }

  static Future<bool> _isDismissed(String tag) async {
    try {
      final f = await _dismissFile();
      return f.existsSync() && f.readAsStringSync().trim() == tag;
    } catch (_) {
      return false;
    }
  }

  static Future<File> _dismissFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'update_dismissed.txt'));
  }

  /// `v1.2.3` / `1.2.3+7` → [1, 2, 3]; null when unparseable.
  static List<int>? _parse(String v) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)').firstMatch(v.trim());
    if (m == null) return null;
    return [1, 2, 3].map((g) => int.parse(m.group(g)!)).toList();
  }

  static bool _newer(List<int> a, List<int> b) {
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }
}
