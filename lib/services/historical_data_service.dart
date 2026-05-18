import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricalRate {
  final DateTime date;
  final double blueSell;
  final double oficialSell;
  final double blueBuy;
  final double oficialBuy;

  HistoricalRate({
    required this.date,
    required this.blueSell,
    required this.oficialSell,
    required this.blueBuy,
    required this.oficialBuy,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'blueSell': blueSell,
        'oficialSell': oficialSell,
        'blueBuy': blueBuy,
        'oficialBuy': oficialBuy,
      };

  factory HistoricalRate.fromJson(Map<String, dynamic> json) => HistoricalRate(
        date: DateTime.parse(json['date']),
        blueSell: (json['blueSell'] as num).toDouble(),
        oficialSell: (json['oficialSell'] as num).toDouble(),
        blueBuy: (json['blueBuy'] as num).toDouble(),
        oficialBuy: (json['oficialBuy'] as num).toDouble(),
      );
}

class HistoricalDataService {
  static const String _key = 'historical_rates';
  static const int _maxDays = 30;

  static Future<void> saveDailyRate({
    required double blueSell,
    required double oficialSell,
    required double blueBuy,
    required double oficialBuy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      List<HistoricalRate> history = [];

      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List;
        history = decoded.map((e) => HistoricalRate.fromJson(e)).toList();
      }

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Evitar duplicados del mismo día (actualizar si ya existe)
      history.removeWhere((r) =>
          r.date.year == todayDate.year &&
          r.date.month == todayDate.month &&
          r.date.day == todayDate.day);

      history.add(HistoricalRate(
        date: todayDate,
        blueSell: blueSell,
        oficialSell: oficialSell,
        blueBuy: blueBuy,
        oficialBuy: oficialBuy,
      ));

      // Ordenar por fecha y limitar
      history.sort((a, b) => a.date.compareTo(b.date));
      if (history.length > _maxDays) {
        history = history.sublist(history.length - _maxDays);
      }

      final encoded = json.encode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_key, encoded);
    } catch (_) {}
  }

  static Future<List<HistoricalRate>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = json.decode(raw) as List;
      return decoded.map((e) => HistoricalRate.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
