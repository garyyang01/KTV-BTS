/// Payment response model for Stripe API
class PaymentResponse {
  final bool success;
  final String? paymentIntentId;
  final String? clientSecret;
  final String? errorMessage;
  final String? status;
  final double? amount;
  final String? currency;

  const PaymentResponse({
    required this.success,
    this.paymentIntentId,
    this.clientSecret,
    this.errorMessage,
    this.status,
    this.amount,
    this.currency,
  });

  /// Create successful payment response
  factory PaymentResponse.success({
    required String paymentIntentId,
    required String clientSecret,
    required String status,
    required double amount,
    required String currency,
  }) {
    return PaymentResponse(
      success: true,
      paymentIntentId: paymentIntentId,
      clientSecret: clientSecret,
      status: status,
      amount: amount,
      currency: currency,
    );
  }

  /// Create failed payment response
  factory PaymentResponse.failure({
    required String errorMessage,
  }) {
    return PaymentResponse(
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// Convert from JSON
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] as bool,
      paymentIntentId: json['payment_intent_id'] as String?,
      clientSecret: json['client_secret'] as String?,
      errorMessage: json['error_message'] as String?,
      status: json['status'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      currency: json['currency'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'payment_intent_id': paymentIntentId,
      'client_secret': clientSecret,
      'error_message': errorMessage,
      'status': status,
      'amount': amount,
      'currency': currency,
    };
  }

  @override
  String toString() {
    return 'PaymentResponse(success: $success, paymentIntentId: $paymentIntentId, status: $status, amount: $amount, currency: $currency, errorMessage: $errorMessage)';
  }
}
