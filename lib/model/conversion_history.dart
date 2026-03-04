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
