import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/historical_data_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<HistoricalRate> _history = [];
  bool _isLoading = true;
  String _selectedMetric = 'sell'; // 'sell' o 'buy'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await HistoricalDataService.loadHistory();
    setState(() {
      _history = data;
      _isLoading = false;
    });
  }

  List<FlSpot> _getBlueSpots() {
    if (_history.isEmpty) return [];
    return _history.asMap().entries.map((entry) {
      final value = _selectedMetric == 'sell'
          ? entry.value.blueSell
          : entry.value.blueBuy;
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  List<FlSpot> _getOficialSpots() {
    if (_history.isEmpty) return [];
    return _history.asMap().entries.map((entry) {
      final value = _selectedMetric == 'sell'
          ? entry.value.oficialSell
          : entry.value.oficialBuy;
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  String _getDayLabel(int index) {
    if (index < 0 || index >= _history.length) return '';
    return DateFormat('dd/MM').format(_history[index].date);
  }

  @override
  Widget build(BuildContext context) {
    final blueSpots = _getBlueSpots();
    final oficialSpots = _getOficialSpots();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(53, 55, 88, 1),
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Evolución del Dólar',
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : _history.length < 2
              ? _buildEmptyState()
              : _buildChart(blueSpots, oficialSpots),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Aún no hay suficientes datos históricos',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los gráficos aparecerán automáticamente a medida que uses la app durante varios días.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                textStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> blueSpots, List<FlSpot> oficialSpots) {
    final minY = _history.isEmpty
        ? 0.0
        : ([
              ..._history.map((h) => h.blueSell),
              ..._history.map((h) => h.oficialSell),
            ].reduce((a, b) => a < b ? a : b) *
            0.95).toDouble();
    final maxY = _history.isEmpty
        ? 100.0
        : ([
              ..._history.map((h) => h.blueSell),
              ..._history.map((h) => h.oficialSell),
            ].reduce((a, b) => a > b ? a : b) *
            1.05).toDouble();

    return Column(
      children: [
        const SizedBox(height: 16),
        // Toggle compra/venta
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'sell', label: Text('Venta')),
              ButtonSegment(value: 'buy', label: Text('Compra')),
            ],
            selected: {_selectedMetric},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedMetric = newSelection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.amberAccent;
                }
                return Colors.white10;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.black;
                }
                return Colors.white70;
              }),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Leyenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.blue, 'Blue'),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.green, 'Oficial'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Gráfico
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 20, left: 10, bottom: 10),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (_history.length / 5).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _history.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getDayLabel(index),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_history.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black.withValues(alpha: 0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isBlue = spot.barIndex == 0;
                        return LineTooltipItem(
                          '\$${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: isBlue ? Colors.blue : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Blue line
                  LineChartBarData(
                    spots: blueSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                  // Oficial line
                  LineChartBarData(
                    spots: oficialSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.green,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Info de días
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'Datos de los últimos ${_history.length} días',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
