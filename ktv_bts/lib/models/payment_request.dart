/// Payment request model for KTV booking
class PaymentRequest {
  final String customerName;
  final bool isAdult;
  final String time; // "Morning" or "Afternoon"
  final double amount; // Will be calculated automatically
  final String currency; // Fixed to EUR
  final String? description;

  const PaymentRequest({
    required this.customerName,
    required this.isAdult,
    required this.time,
    this.amount = 0.0, // Will be calculated based on isAdult
    this.currency = 'EUR', // Fixed to EUR
    this.description,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'is_adult': isAdult,
      'time': time,
      'amount': amount,
      'currency': currency,
      'description': description,
    };
  }

  /// Create from JSON
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      customerName: json['customer_name'] as String,
      isAdult: json['is_adult'] as bool,
      time: json['time'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      description: json['description'] as String?,
    );
  }

  @override
  String toString() {
    return 'PaymentRequest(customerName: $customerName, isAdult: $isAdult, time: $time, amount: $amount, currency: $currency)';
  }
}
