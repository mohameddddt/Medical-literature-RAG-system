import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_entry.dart';

/// Stores recent searches on the device. Deliberately capped so the stored
/// payload stays small and the history screen stays scannable.
class HistoryService extends ChangeNotifier {
  static const _key = 'search_history';
  static const maxEntries = 50;

  List<SearchEntry> _entries = [];
  List<SearchEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _entries = raw
        .map((s) {
          try {
            return SearchEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<SearchEntry>()
        .toList();
    notifyListeners();
  }

  Future<void> add(SearchEntry entry) async {
    // Collapse repeat searches of the same question to the most recent one.
    _entries.removeWhere(
      (e) => e.question.toLowerCase() == entry.question.toLowerCase(),
    );
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(SearchEntry entry) async {
    _entries.remove(entry);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries = [];
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
