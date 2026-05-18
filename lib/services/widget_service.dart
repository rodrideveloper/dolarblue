import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const String _prefsKeyBlueSell = 'widget_blue_sell';
  static const String _prefsKeyOficialSell = 'widget_oficial_sell';
  static const String _prefsKeyUpdateTime = 'widget_update_time';
  static const String _prefsKeyBlueBuy = 'widget_blue_buy';
  static const String _prefsKeyOficialBuy = 'widget_oficial_buy';

  static Future<void> updateWidgetData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.bluelytics.com.ar/v2/latest'),
      );

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final blueSell = (data['blue']?['value_sell'] ?? 0).toDouble();
      final blueBuy = (data['blue']?['value_buy'] ?? 0).toDouble();
      final oficialSell = (data['oficial']?['value_sell'] ?? 0).toDouble();
      final oficialBuy = (data['oficial']?['value_buy'] ?? 0).toDouble();

      final df = DateFormat('HH:mm');
      final now = df.format(DateTime.now());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyBlueSell, '\$${blueSell.toStringAsFixed(0)}');
      await prefs.setString(_prefsKeyBlueBuy, '\$${blueBuy.toStringAsFixed(0)}');
      await prefs.setString(_prefsKeyOficialSell, '\$${oficialSell.toStringAsFixed(0)}');
      await prefs.setString(_prefsKeyOficialBuy, '\$${oficialBuy.toStringAsFixed(0)}');
      await prefs.setString(_prefsKeyUpdateTime, now);
    } catch (_) {}
  }

  static Future<Map<String, String?>> getLastValues() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'blue_sell': prefs.getString(_prefsKeyBlueSell),
      'oficial_sell': prefs.getString(_prefsKeyOficialSell),
    };
  }
}
