import 'package:dolarblue/api/dolar_api.dart';
import 'package:dolarblue/model/conversion_history.dart';
import 'package:dolarblue/model/dolar_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class Inicio extends StatelessWidget {
  const Inicio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.white),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amberAccent),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amberAccent),
            ),
            disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white38))),
        textTheme: const TextTheme(
            titleMedium: TextStyle(color: Colors.white, fontSize: 20)),
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

  // Datos de cotizaciones
  DolarModel? _dolarData;
  String _selectedDolar = 'blue';
  bool isEnabled = false;
  bool _isLoading = true;

  // Historial de conversiones
  final List<ConversionHistory> _history = [];

  // Tipos de dólar disponibles
  final Map<String, String> _dolarTypes = {
    'blue': 'Dólar Blue',
    'oficial': 'Dólar Oficial',
  };

  @override
  void initState() {
    super.initState();
    _loadDolarData();
  }

  Future<void> _loadDolarData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DolarApi().fetchDolar();
      setState(() {
        _dolarData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double? _getCurrentRate() {
    if (_dolarData == null) return null;
    switch (_selectedDolar) {
      case 'blue':
        return _dolarData!.blue?.valueBuy;
      case 'oficial':
        return _dolarData!.oficial?.valueBuy;
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
    final fecha = df.format(DateTime.parse(_dolarData!.lastUpdate!));

    final mensaje = '''
💵 *Cotización del Dólar* 💵

🔵 *Dólar Blue*
   Compra: \$${blueCompra.toStringAsFixed(2)}
   Venta: \$${blueVenta.toStringAsFixed(2)}

🏦 *Dólar Oficial*
   Compra: \$${oficialCompra.toStringAsFixed(2)}
   Venta: \$${oficialVenta.toStringAsFixed(2)}

📅 Actualizado: $fecha

📱 Enviado desde DolarBlue App
''';

    Share.share(mensaje);
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

      // Agregar al historial
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
        // Mantener solo las últimas 10 conversiones
        if (_history.length > 10) {
          _history.removeLast();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un valor válido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Header con logo y botón compartir
          _buildHeader(),
          const SizedBox(height: 10),
          // Cotizaciones
          _buildCotizaciones(),
          const SizedBox(height: 20),
          // Panel principal - expandido para llenar el resto
          Expanded(child: _buildMainPanel()),
        ],
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
          IconButton(
            onPressed: _dolarData != null ? _compartirCotizacion : null,
            icon: const Icon(Icons.share, color: Colors.black, size: 28),
            tooltip: 'Compartir cotización',
          ),
        ],
      ),
    );
  }

  Widget _buildCotizaciones() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      );
    }

    if (_dolarData == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Error al cargar cotizaciones'),
      );
    }

    return Column(
      children: [
        // Cards de cotizaciones
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildDolarCard(
                  'Blue',
                  _dolarData!.blue?.valueBuy ?? 0,
                  _dolarData!.blue?.valueSell ?? 0,
                  Colors.blue.shade700,
                  'blue',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDolarCard(
                  'Oficial',
                  _dolarData!.oficial?.valueBuy ?? 0,
                  _dolarData!.oficial?.valueSell ?? 0,
                  Colors.green.shade700,
                  'oficial',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Fecha de actualización
        Text(
          'Actualizado: ${df.format(DateTime.parse(_dolarData!.lastUpdate!))}',
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(color: Colors.black54, fontSize: 12),
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
          // Limpiar campos al cambiar tipo
          pesoc.clear();
          dolarc.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Compra',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '\$${compra.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 16,
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
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '\$${venta.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 16,
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
            // Historial
            _buildHistorial(),
            const SizedBox(height: 20),
            // Footer
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'rodrigo.desarrollador@gmail.com',
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
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
                onPressed: () {
                  setState(() => _history.clear());
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
                  color: Colors.white.withOpacity(0.1),
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
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      item.formattedTime,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
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
}
