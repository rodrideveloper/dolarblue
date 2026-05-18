import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/conversion_history.dart';

class HistoryService {
  static const String _key = 'conversion_history';
  static const int _maxItems = 20;

  Future<List<ConversionHistory>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final List decoded = json.decode(raw) as List;
      return decoded
          .map((e) => ConversionHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<ConversionHistory> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limited = history.length > _maxItems
          ? history.sublist(0, _maxItems)
          : history;
      final encoded =
          json.encode(limited.map((e) => e.toJson()).toList());
      await prefs.setString(_key, encoded);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
