import 'package:dolarblue/api/dolar_api.dart';
import 'package:dolarblue/model/conversion_history.dart';
import 'package:dolarblue/model/dolar_model.dart';
import 'package:dolarblue/chart_screen.dart';
import 'package:dolarblue/services/historical_data_service.dart';
import 'package:dolarblue/services/history_service.dart';
import 'package:dolarblue/services/widget_service.dart';
import 'package:dolarblue/settings_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Inicio extends StatelessWidget {
  const Inicio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromRGBO(53, 55, 88, 1),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amberAccent),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amberAccent),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      home: const Scaffold(
        backgroundColor: Colors.amberAccent,
        body: Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final pesoc = TextEditingController();
  final dolarc = TextEditingController();
  final df = DateFormat('dd-MM-yyyy hh:mm a');

  DolarModel? _dolarData;
  String _selectedDolar = 'blue';
  bool isEnabled = false;
  bool _isLoading = true;
  bool _isOffline = false;

  final List<ConversionHistory> _history = [];
  final HistoryService _historyService = HistoryService();

  final Map<String, String> _dolarTypes = {
    'blue': 'Dólar Blue',
    'oficial': 'Dólar Oficial',
    'blue_euro': 'Euro Blue',
    'oficial_euro': 'Euro Oficial',
  };



  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadDolarData();
    _maybeAskReview();
  }

  Future<void> _loadHistory() async {
    final loaded = await _historyService.loadHistory();
    if (mounted) {
      setState(() {
        _history.addAll(loaded);
      });
    }
  }

  Future<void> _saveHistory() async {
    await _historyService.saveHistory(_history);
  }

  Future<void> _loadDolarData() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });
    try {
      final data = await DolarApi().fetchDolar();
      await WidgetService.updateWidgetData();

      // Guardar datos históricos
      if (data.blue?.valueSell != null && data.oficial?.valueSell != null) {
        await HistoricalDataService.saveDailyRate(
          blueSell: data.blue!.valueSell!,
          oficialSell: data.oficial!.valueSell!,
          blueBuy: data.blue!.valueBuy ?? data.blue!.valueSell!,
          oficialBuy: data.oficial!.valueBuy ?? data.oficial!.valueSell!,
        );
      }

      setState(() {
        _dolarData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  Future<void> _maybeAskReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'app_launches';
      int launches = (prefs.getInt(key) ?? 0) + 1;
      await prefs.setInt(key, launches);
      if (launches == 5) {
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        }
      }
    } catch (_) {}
  }

  double? _getCurrentRate() {
    if (_dolarData == null) return null;
    switch (_selectedDolar) {
      case 'blue':
        return _dolarData!.blue?.valueBuy;
      case 'oficial':
        return _dolarData!.oficial?.valueBuy;
      case 'blue_euro':
        return _dolarData!.blueEuro?.valueBuy;
      case 'oficial_euro':
        return _dolarData!.oficialEuro?.valueBuy;
      default:
        return _dolarData!.blue?.valueBuy;
    }
  }

  void _compartirCotizacion() {
    if (_dolarData == null) return;

    final blueCompra = _dolarData!.blue?.valueBuy ?? 0;
    final blueVenta = _dolarData!.blue?.valueSell ?? 0;
    final oficialCompra = _dolarData!.oficial?.valueBuy ?? 0;
    final oficialVenta = _dolarData!.oficial?.valueSell ?? 0;
    final fecha = _dolarData!.lastUpdate != null
        ? df.format(DateTime.parse(_dolarData!.lastUpdate!))
        : 'N/A';

    final mensaje = '''
🇦🇷💵 *Cotización del Dólar - DolarBlue* 💵🇦🇷

🔵 *Dólar Blue*
   Compra: \$${blueCompra.toStringAsFixed(2)}
   Venta: \$${blueVenta.toStringAsFixed(2)}

🏦 *Dólar Oficial*
   Compra: \$${oficialCompra.toStringAsFixed(2)}
   Venta: \$${oficialVenta.toStringAsFixed(2)}

📅 Actualizado: $fecha

📱 Descargá DolarBlue en Play Store
'''
        ;

    SharePlus.instance.share(ShareParams(text: mensaje));
  }

  void _cambioDivisa() {
    final rate = _getCurrentRate();
    if (rate == null) return;

    double pesoAmount = 0;
    double dolarAmount = 0;

    try {
      if (!isEnabled) {
        pesoAmount = double.parse(pesoc.text);
        dolarAmount = pesoAmount / rate;
        dolarc.text = dolarAmount.toStringAsFixed(2);
      } else {
        dolarAmount = double.parse(dolarc.text);
        pesoAmount = dolarAmount * rate;
        pesoc.text = pesoAmount.toStringAsFixed(0);
      }

      setState(() {
        _history.insert(
          0,
          ConversionHistory(
            pesoAmount: pesoAmount,
            dolarAmount: dolarAmount,
            rate: rate,
            dolarType: _dolarTypes[_selectedDolar] ?? 'Blue',
            timestamp: DateTime.now(),
            pesoToDolar: !isEnabled,
          ),
        );
        if (_history.length > 20) {
          _history.removeLast();
        }
      });
      _saveHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un valor válido')),
      );
    }
  }

  double _calcularBrecha() {
    if (_dolarData?.oficial?.valueSell == null ||
        _dolarData?.blue?.valueSell == null) {
      return 0;
    }
    final oficial = _dolarData!.oficial!.valueSell!;
    final blue = _dolarData!.blue!.valueSell!;
    if (oficial == 0) return 0;
    return ((blue - oficial) / oficial) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadDolarData,
        color: Colors.amberAccent,
        backgroundColor: const Color.fromRGBO(53, 55, 88, 1),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 10),
            _buildCotizaciones(),
            const SizedBox(height: 20),
            Expanded(child: _buildMainPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: SvgPicture.asset("android/assets/images/dolarsvg.svg"),
          ),
          Text(
            'DolarBlue',
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChartScreen()),
                  );
                },
                icon: const Icon(Icons.show_chart, color: Colors.black, size: 28),
                tooltip: 'Ver evolución',
              ),
              IconButton(
                onPressed: _dolarData != null ? _compartirCotizacion : null,
                icon: const Icon(Icons.share, color: Colors.black, size: 28),
                tooltip: 'Compartir cotización',
              ),
              IconButton(
                onPressed: _showSettings,
                icon: const Icon(Icons.settings, color: Colors.black, size: 28),
                tooltip: 'Configuración',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCotizaciones() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (_dolarData == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Error al cargar cotizaciones',
                style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loadDolarData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(53, 55, 88, 1),
                foregroundColor: Colors.amberAccent,
              ),
            ),
          ],
        ),
      );
    }

    final brecha = _calcularBrecha();

    return Column(
      children: [
        // Cards de cotizaciones
        SizedBox(
          height: 95,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildDolarCard(
                'Blue',
                _dolarData!.blue?.valueBuy ?? 0,
                _dolarData!.blue?.valueSell ?? 0,
                Colors.blue.shade700,
                'blue',
              ),
              const SizedBox(width: 10),
              _buildDolarCard(
                'Oficial',
                _dolarData!.oficial?.valueBuy ?? 0,
                _dolarData!.oficial?.valueSell ?? 0,
                Colors.green.shade700,
                'oficial',
              ),
              const SizedBox(width: 10),
              _buildDolarCard(
                'Euro Blue',
                _dolarData!.blueEuro?.valueBuy ?? 0,
                _dolarData!.blueEuro?.valueSell ?? 0,
                Colors.purple.shade700,
                'blue_euro',
              ),
              const SizedBox(width: 10),
              _buildDolarCard(
                'Euro Ofic.',
                _dolarData!.oficialEuro?.valueBuy ?? 0,
                _dolarData!.oficialEuro?.valueSell ?? 0,
                Colors.teal.shade700,
                'oficial_euro',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Brecha
        if (brecha > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Brecha Blue vs Oficial: ${brecha.toStringAsFixed(1)}%',
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        // Fecha de actualización
        Text(
          'Actualizado: ${_dolarData!.lastUpdate != null ? df.format(DateTime.parse(_dolarData!.lastUpdate!)) : 'N/A'}',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        if (_isOffline)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Modo offline - Mostrando datos cacheados',
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDolarCard(
      String title, double compra, double venta, Color color, String type) {
    final isSelected = _selectedDolar == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDolar = type;
          pesoc.clear();
          dolarc.clear();
        });
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Compra',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.black54,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '\$${compra.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Venta',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.black54,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '\$${venta.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 25),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(53, 55, 88, 1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(37.5),
          topRight: Radius.circular(37.5),
        ),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Indicador de tipo seleccionado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amberAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Calculando con ${_dolarTypes[_selectedDolar]}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _camposDatos(),
            const SizedBox(height: 20),
            _buildBotonCalcular(),
            const SizedBox(height: 20),
            _buildHistorial(),
            const SizedBox(height: 20),
            // Fuente de datos
            TextButton.icon(
              onPressed: () => _launchUrl('https://bluelytics.com.ar'),
              icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white54),
              label: Text(
                'Datos vía Bluelytics.com.ar',
                style: GoogleFonts.montserrat(
                  textStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Footer
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'DolarBlue Argentina',
                    style: GoogleFonts.pacifico(
                      textStyle:
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _camposDatos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _campoPeso()),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              setState(() {
                dolarc.text = '';
                pesoc.text = '';
                isEnabled = !isEnabled;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'android/assets/images/changedolar.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(child: _campoDolar()),
        ],
      ),
    );
  }

  Widget _buildBotonCalcular() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(110, 110),
        shape: const CircleBorder(),
        backgroundColor: Colors.amberAccent,
        padding: EdgeInsets.zero,
      ),
      onPressed: _cambioDivisa,
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Calcular',
          style: TextStyle(fontSize: 15, color: Colors.black),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildHistorial() {
    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Tu historial de conversiones aparecerá aquí',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📋 Historial',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () async {
                  setState(() => _history.clear());
                  await _historyService.clearHistory();
                },
                child: const Text(
                  'Limpiar',
                  style: TextStyle(color: Colors.amberAccent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.dolarType,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      item.formattedTime,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _campoPeso() {
    return TextField(
      autofocus: false,
      enabled: !isEnabled,
      keyboardType: TextInputType.number,
      controller: pesoc,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Peso',
        prefixText: '\$ ',
        prefixStyle: TextStyle(color: Colors.white),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  Widget _campoDolar() {
    return TextField(
      enabled: isEnabled,
      keyboardType: TextInputType.number,
      controller: dolarc,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'USD',
        prefixText: 'US\$ ',
        prefixStyle: TextStyle(color: Colors.white),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(53, 55, 88, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const SettingsBottomSheet();
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
