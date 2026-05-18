import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/dolar_model.dart';

class DolarApi {
  static const String _cacheKey = 'dolar_cache';
  static const String _cacheTimeKey = 'dolar_cache_time';

  Future<DolarModel> fetchDolar() async {
    final response = await http.get(
      Uri.parse('https://api.bluelytics.com.ar/v2/latest'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final model = DolarModel.fromJson(data);
      await _saveCache(data);
      return model;
    } else {
      // Intentar devolver cache si existe
      final cached = await _getCache();
      if (cached != null) {
        return DolarModel.fromJson(cached);
      }
      throw Exception('Error al cargar los datos');
    }
  }

  Future<void> _saveCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _getCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        return json.decode(cached) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getLastUpdateString() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_cacheTimeKey);
      if (ms != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        return dt.toIso8601String();
      }
    } catch (_) {}
    return null;
  }
}
