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
  
  /// Create payment method with card details
  Future<PaymentResponse> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  });
  
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
  PaymentResponse? _lastPaymentIntent;
  
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
      
      // Stripe initialization completed
      
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
        final paymentResponse = PaymentResponse.success(
          paymentIntentId: data['id'],
          clientSecret: data['client_secret'],
          status: data['status'],
          amount: amount,
          currency: request.currency,
        );
        _lastPaymentIntent = paymentResponse;
        return paymentResponse;
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
  Future<PaymentResponse> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('Service not initialized. Call initialize() first.');
      }

      // Create payment method using Stripe API directly
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      // Use test token for card
      final testToken = _getTestTokenForCard(cardNumber);
      
      final body = {
        'type': 'card',
        'card[token]': testToken,
        'billing_details[name]': cardholderName,
      };

      final response = await http.post(
        Uri.parse('$_stripeApiBaseUrl/payment_methods'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.success(
          paymentIntentId: data['id'], // 這裡返回 PaymentMethod ID
          clientSecret: null,
          status: 'created',
          amount: 0, // PaymentMethod 沒有金額
          currency: 'EUR',
        );
      } else {
        final errorData = json.decode(response.body);
        return PaymentResponse.failure(
          errorMessage: errorData['error']?['message'] ?? 'Payment method creation failed',
        );
      }
    } catch (e) {
      return PaymentResponse.failure(
        errorMessage: 'Payment method creation failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentResponse> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      // For now, we'll use the server-side confirmation approach
      // This maintains compatibility with the existing flow
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
        errorMessage: 'Payment confirmation failed: ${e.toString()}',
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

  /// Calculate KTV booking amount based on ticket request
  double _calculateAmount(PaymentRequest request) {
    // If ticketRequest is provided, calculate from ticket info
    if (request.ticketRequest != null) {
      return request.ticketRequest!.totalAmount;
    }
    
    // Fallback to legacy single ticket calculation
    if (request.isAdult) {
      return 19.0; // Adult: 19 EUR (fixed)
    } else {
      return 0.0; // Child: 0 EUR (free)
    }
  }

  /// Generate description for payment
  String _generateDescription(PaymentRequest request) {
    // If ticketRequest is provided, generate description from ticket info
    if (request.ticketRequest != null) {
      final ticketRequest = request.ticketRequest!;
      final adultCount = ticketRequest.adultTickets.length;
      final childCount = ticketRequest.childTickets.length;
      
      if (adultCount > 0 && childCount > 0) {
        return 'Neuschwanstein Castle Tickets - $adultCount Adult(s), $childCount Child(ren) - ${ticketRequest.ticketInfo.first.session} Session';
      } else if (adultCount > 0) {
        return 'Neuschwanstein Castle Tickets - $adultCount Adult(s) - ${ticketRequest.ticketInfo.first.session} Session';
      } else {
        return 'Neuschwanstein Castle Tickets - $childCount Child(ren) - ${ticketRequest.ticketInfo.first.session} Session';
      }
    }
    
    // Fallback to legacy single ticket description
    final customerType = request.isAdult ? 'Adult' : 'Child';
    return 'Neuschwanstein Castle Ticket - $customerType - ${request.time} Session';
  }

  /// Get public key for client-side Stripe initialization
  String get publicKey => _publicKey;

  /// 根據卡號獲取對應的 Stripe 測試 token
  /// 這些是 Stripe 提供的測試 token，用於模擬不同的卡號
  String _getTestTokenForCard(String cardNumber) {
    // 移除空格和格式化字符
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    // 根據卡號前幾位判斷卡類型並返回對應的測試 token
    if (cleanCardNumber.startsWith('4242')) {
      // Visa 成功卡
      return 'tok_visa';
    } else if (cleanCardNumber.startsWith('4000')) {
      // Visa 拒絕卡
      return 'tok_chargeDeclined';
    } else if (cleanCardNumber.startsWith('5555')) {
      // Mastercard 成功卡
      return 'tok_mastercard';
    } else if (cleanCardNumber.startsWith('3782')) {
      // American Express 成功卡
      return 'tok_amex';
    } else if (cleanCardNumber.startsWith('6011')) {
      // Discover 成功卡
      return 'tok_discover';
    } else {
      // 默認使用 Visa 成功卡
      return 'tok_visa';
    }
  }
}
