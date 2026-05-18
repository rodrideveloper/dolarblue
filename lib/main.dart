import 'package:flutter/material.dart';
import 'package:dolarblue/services/background_worker.dart';
import 'package:dolarblue/services/notification_service.dart';
import 'package:dolarblue/services/widget_service.dart';
import 'inicio_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  await BackgroundWorker.initialize();
  await BackgroundWorker.registerPeriodicTask();
  await WidgetService.updateWidgetData();

  runApp(const Inicio());
}
