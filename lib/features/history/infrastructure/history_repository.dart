import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/history_entry.dart';

const _kHistoryKey = 'lunar_stack.history_entries';

class HistoryRepository {
  Future<List<HistoryEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? const [];
    return raw
        .map((s) => HistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> add(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    // Copy before mutating: the `const []` fallback (and, depending on the
    // platform impl, the stored list itself) is unmodifiable — calling .add
    // on it throws and silently drops the entry upstream.
    final raw = List<String>.of(prefs.getStringList(_kHistoryKey) ?? const []);
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_kHistoryKey, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }
}
