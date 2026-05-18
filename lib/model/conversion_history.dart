class ConversionHistory {
  final double pesoAmount;
  final double dolarAmount;
  final double rate;
  final String dolarType;
  final DateTime timestamp;
  final bool pesoToDolar;

  ConversionHistory({
    required this.pesoAmount,
    required this.dolarAmount,
    required this.rate,
    required this.dolarType,
    required this.timestamp,
    required this.pesoToDolar,
  });

  factory ConversionHistory.fromJson(Map<String, dynamic> json) {
    return ConversionHistory(
      pesoAmount: (json['pesoAmount'] as num).toDouble(),
      dolarAmount: (json['dolarAmount'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      dolarType: json['dolarType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      pesoToDolar: json['pesoToDolar'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pesoAmount': pesoAmount,
      'dolarAmount': dolarAmount,
      'rate': rate,
      'dolarType': dolarType,
      'timestamp': timestamp.toIso8601String(),
      'pesoToDolar': pesoToDolar,
    };
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get description {
    if (pesoToDolar) {
      return '\$${pesoAmount.toStringAsFixed(0)} → USD ${dolarAmount.toStringAsFixed(2)}';
    } else {
      return 'USD ${dolarAmount.toStringAsFixed(2)} → \$${pesoAmount.toStringAsFixed(0)}';
    }
  }
}
