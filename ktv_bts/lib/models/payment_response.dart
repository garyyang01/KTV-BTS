/// Payment response model for Stripe API
class PaymentResponse {
  final bool success;
  final String? paymentIntentId;
  final String? clientSecret;
  final String? errorMessage;
  final String? status;
  final double? amount;
  final String? currency;
  final bool requiresAction; // For 3DS authentication

  const PaymentResponse({
    required this.success,
    this.paymentIntentId,
    this.clientSecret,
    this.errorMessage,
    this.status,
    this.amount,
    this.currency,
    this.requiresAction = false,
  });

  /// Create successful payment response
  factory PaymentResponse.success({
    required String paymentIntentId,
    String? clientSecret,
    String? status,
    double? amount,
    String? currency,
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
    String? paymentIntentId,
    String? clientSecret,
    bool requiresAction = false,
  }) {
    return PaymentResponse(
      success: false,
      errorMessage: errorMessage,
      paymentIntentId: paymentIntentId,
      clientSecret: clientSecret,
      requiresAction: requiresAction,
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
      requiresAction: json['requires_action'] as bool? ?? false,
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
      'requires_action': requiresAction,
    };
  }

  @override
  String toString() {
    return 'PaymentResponse(success: $success, paymentIntentId: $paymentIntentId, status: $status, amount: $amount, currency: $currency, errorMessage: $errorMessage)';
  }
}
