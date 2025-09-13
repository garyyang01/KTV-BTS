import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';

/// Interface for Stripe payment operations
abstract class IStripePaymentService {
  /// Initialize Stripe with API keys
  Future<void> initialize();
  
  /// Create payment intent for KTV booking
  Future<PaymentResponse> createPaymentIntent(PaymentRequest request);
  
  /// Confirm payment with payment method
  Future<PaymentResponse> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  });
  
  /// Cancel payment intent
  Future<PaymentResponse> cancelPayment(String paymentIntentId);
  
  /// Get payment status
  Future<PaymentResponse> getPaymentStatus(String paymentIntentId);
}

/// Implementation of Stripe payment service
class StripePaymentService implements IStripePaymentService {
  static const String _stripeApiBaseUrl = 'https://api.stripe.com/v1';
  
  bool _isInitialized = false;
  
  /// Get Stripe public key from environment variables
  String get _publicKey => EnvConfig.stripePublicKey;
  
  /// Get Stripe secret key from environment variables
  String get _secretKey => EnvConfig.stripeSecretKey;

  @override
  Future<void> initialize() async {
    try {
      // Initialize environment configuration
      await EnvConfig.initialize();
      
      // Validate that required environment variables are present
      EnvConfig.validateRequiredVars();
      
      _isInitialized = true;
    } catch (e) {
      // 如果環境變數載入失敗，拋出更清楚的錯誤訊息
      throw Exception('Stripe API 金鑰未設定。請檢查 .env 檔案是否存在並包含正確的 STRIPE_PUBLIC_KEY 和 STRIPE_SECRET_KEY。\n\n錯誤詳情: $e');
    }
  }

  @override
  Future<PaymentResponse> createPaymentIntent(PaymentRequest request) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Calculate amount based on KTV pricing logic
      final amount = _calculateAmount(request);
      
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final body = {
        'amount': (amount * 100).round().toString(), // Convert to cents
        'currency': request.currency.toLowerCase(),
        'description': request.description ?? _generateDescription(request),
        'metadata[customer_name]': request.customerName,
        'metadata[is_adult]': request.isAdult.toString(),
        'metadata[time]': request.time,
        'automatic_payment_methods[enabled]': 'true',
        'automatic_payment_methods[allow_redirects]': 'never',
      };

      final response = await http.post(
        Uri.parse('$_stripeApiBaseUrl/payment_intents'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.success(
          paymentIntentId: data['id'],
          clientSecret: data['client_secret'],
          status: data['status'],
          amount: amount,
          currency: request.currency,
        );
      } else {
        final errorData = json.decode(response.body);
        return PaymentResponse.failure(
          errorMessage: errorData['error']?['message'] ?? 'Payment intent creation failed',
        );
      }
    } catch (e) {
      return PaymentResponse.failure(
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentResponse> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final body = {
        'payment_method': paymentMethodId,
      };

      final response = await http.post(
        Uri.parse('$_stripeApiBaseUrl/payment_intents/$paymentIntentId/confirm'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.success(
          paymentIntentId: data['id'],
          clientSecret: data['client_secret'],
          status: data['status'],
          amount: (data['amount'] as num).toDouble() / 100, // Convert from cents
          currency: data['currency'].toString().toUpperCase(),
        );
      } else {
        final errorData = json.decode(response.body);
        return PaymentResponse.failure(
          errorMessage: errorData['error']?['message'] ?? 'Payment confirmation failed',
        );
      }
    } catch (e) {
      return PaymentResponse.failure(
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentResponse> cancelPayment(String paymentIntentId) async {
    try {
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final response = await http.post(
        Uri.parse('$_stripeApiBaseUrl/payment_intents/$paymentIntentId/cancel'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.success(
          paymentIntentId: data['id'],
          clientSecret: data['client_secret'],
          status: data['status'],
          amount: (data['amount'] as num).toDouble() / 100,
          currency: data['currency'].toString().toUpperCase(),
        );
      } else {
        final errorData = json.decode(response.body);
        return PaymentResponse.failure(
          errorMessage: errorData['error']?['message'] ?? 'Payment cancellation failed',
        );
      }
    } catch (e) {
      return PaymentResponse.failure(
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentResponse> getPaymentStatus(String paymentIntentId) async {
    try {
      final headers = {
        'Authorization': 'Bearer $_secretKey',
      };

      final response = await http.get(
        Uri.parse('$_stripeApiBaseUrl/payment_intents/$paymentIntentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.success(
          paymentIntentId: data['id'],
          clientSecret: data['client_secret'],
          status: data['status'],
          amount: (data['amount'] as num).toDouble() / 100,
          currency: data['currency'].toString().toUpperCase(),
        );
      } else {
        final errorData = json.decode(response.body);
        return PaymentResponse.failure(
          errorMessage: errorData['error']?['message'] ?? 'Failed to get payment status',
        );
      }
    } catch (e) {
      return PaymentResponse.failure(
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Calculate KTV booking amount based on customer type
  double _calculateAmount(PaymentRequest request) {
    // KTV pricing logic - Fixed EUR pricing
    if (request.isAdult) {
      return 20.0; // Adult: 20 EUR (fixed)
    } else {
      return 0.0; // Child: 0 EUR (free)
    }
  }

  /// Generate description for payment
  String _generateDescription(PaymentRequest request) {
    final customerType = request.isAdult ? 'Adult' : 'Child';
    return 'KTV Booking - $customerType - ${request.time} Session';
  }

  /// Get public key for client-side Stripe initialization
  String get publicKey => _publicKey;
}
