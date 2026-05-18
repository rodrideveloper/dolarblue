import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({Key? key}) : super(key: key);

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  bool _notificationsEnabled = true;
  double _threshold = 5.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final threshold = prefs.getDouble('notification_threshold');
    setState(() {
      _notificationsEnabled = threshold != null && threshold > 0;
      _threshold = threshold != null && threshold > 0 ? threshold : 5.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_notificationsEnabled) {
      await prefs.setDouble('notification_threshold', _threshold);
    } else {
      await prefs.setDouble('notification_threshold', 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Configuración',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'Alertas de variación',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Notificar cuando el dólar blue varía significativamente',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _notificationsEnabled,
              activeTrackColor: Colors.amberAccent,
              inactiveTrackColor: Colors.white24,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.grey;
              }),
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSettings();
              },
            ),
            if (_notificationsEnabled) ...[
              const SizedBox(height: 10),
              const Text(
                'Umbral de variación',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _threshold,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: Colors.amberAccent,
                      inactiveColor: Colors.white24,
                      label: '${_threshold.toStringAsFixed(0)}%',
                      onChanged: (value) {
                        setState(() => _threshold = value);
                      },
                      onChangeEnd: (_) => _saveSettings(),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${_threshold.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'Las notificaciones se verifican cada ~30 minutos.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
