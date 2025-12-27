class CommissionCalculator {
  static const double commissionRate = 0.10;

  static CommissionResult calculate(double grossAmount) {
    if (grossAmount < 0) {
      throw ArgumentError('Gross amount cannot be negative');
    }
    final commission = double.parse((grossAmount * commissionRate).toStringAsFixed(2));
    final net = double.parse((grossAmount - commission).toStringAsFixed(2));
    return CommissionResult(gross: grossAmount, commission: commission, net: net);
  }
}

class CommissionResult {
  final double gross;
  final double commission;
  final double net;

  const CommissionResult({
    required this.gross,
    required this.commission,
    required this.net,
  });
}
