import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'widget_service.dart';

const String taskName = 'dolarblue-background-update';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Actualizar datos del widget
      await WidgetService.updateWidgetData();

      // Verificar variación para notificación
      await _checkPriceVariation();

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

Future<void> _checkPriceVariation() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final thresholdKey = 'notification_threshold';
    final threshold = prefs.getDouble(thresholdKey) ?? 5.0; // default 5%

    if (threshold <= 0) return; // notificaciones desactivadas

    final response = await http.get(
      Uri.parse('https://api.bluelytics.com.ar/v2/latest'),
    );
    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final currentBlue = (data['blue']?['value_sell'] ?? 0).toDouble();

    final lastKey = 'last_notified_blue_value';
    final lastValue = prefs.getDouble(lastKey);

    if (lastValue != null && lastValue > 0) {
      final variation = ((currentBlue - lastValue) / lastValue) * 100;
      if (variation.abs() >= threshold) {
        String direction = variation > 0 ? 'subió' : 'bajó';
        await NotificationService.showPriceAlert(
          title: 'DolarBlue - Alerta de precio',
          body: 'El dólar blue $direction un ${variation.abs().toStringAsFixed(1)}%. Ahora: \$${currentBlue.toStringAsFixed(0)}',
        );
      }
    }

    await prefs.setDouble(lastKey, currentBlue);
  } catch (_) {}
}

class BackgroundWorker {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> cancelTask() async {
    await Workmanager().cancelByUniqueName(taskName);
  }
}
