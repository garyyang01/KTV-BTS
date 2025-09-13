/// Test configuration for KTV BTS Payment Service
/// 
/// This file contains configuration constants and utilities for testing

// Import required classes
import '../models/payment_request.dart';
import '../models/payment_response.dart';

class TestConfig {
  // Test environment variables
  static const String testEnvFile = '.env.test';
  static const String testPublicKey = 'pk_test_mock_public_key_for_testing';
  static const String testSecretKey = 'sk_test_mock_secret_key_for_testing';
  
  // Test data constants
  static const String testCustomerName = 'Test Customer';
  static const String testPaymentIntentId = 'pi_test_123456789';
  static const String testPaymentMethodId = 'pm_test_123456789';
  static const String testClientSecret = 'pi_test_123456789_secret_abc123';
  
  // Test amounts (in EUR)
  static const double adultPrice = 20.0; // Adult: 20 EUR (fixed)
  static const double childPrice = 0.0; // Child: 0 EUR (free)
  
  // Test URLs
  static const String stripeApiBaseUrl = 'https://api.stripe.com/v1';
  static const String testPaymentIntentUrl = '$stripeApiBaseUrl/payment_intents';
  
  // Test timeouts
  static const Duration testTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  
  /// Get test payment request for adult session
  static PaymentRequest getAdultRequest() {
    return const PaymentRequest(
      customerName: testCustomerName,
      isAdult: true,
      time: 'Morning',
      amount: adultPrice,
      currency: 'EUR',
      description: 'Test Adult Session',
    );
  }
  
  /// Get test payment request for child session
  static PaymentRequest getChildRequest() {
    return const PaymentRequest(
      customerName: testCustomerName,
      isAdult: false,
      time: 'Afternoon',
      amount: childPrice,
      currency: 'EUR',
      description: 'Test Child Session',
    );
  }
  
  /// Get successful payment response mock
  static PaymentResponse getSuccessfulPaymentResponse() {
    return PaymentResponse.success(
      paymentIntentId: testPaymentIntentId,
      clientSecret: testClientSecret,
      status: 'requires_payment_method',
      amount: adultPrice,
      currency: 'EUR',
    );
  }
  
  /// Get failed payment response mock
  static PaymentResponse getFailedPaymentResponse() {
    return PaymentResponse.failure(
      errorMessage: 'Test error message',
    );
  }
  
  /// Validate test environment
  static bool validateTestEnvironment() {
    // Add validation logic here
    // For example: check if test files exist, environment variables are set, etc.
    return true;
  }
}

/// Test data factory for creating various test scenarios
class TestDataFactory {
  /// Create payment request with custom parameters
  static PaymentRequest createPaymentRequest({
    String? customerName,
    bool? isAdult,
    String? time,
    double? amount,
    String? currency,
    String? description,
  }) {
    return PaymentRequest(
      customerName: customerName ?? TestConfig.testCustomerName,
      isAdult: isAdult ?? true,
      time: time ?? 'Morning',
      amount: amount ?? TestConfig.adultPrice,
      currency: currency ?? 'EUR',
      description: description ?? 'Test Payment Request',
    );
  }
  
  /// Create payment response with custom parameters
  static PaymentResponse createPaymentResponse({
    bool? success,
    String? paymentIntentId,
    String? clientSecret,
    String? status,
    double? amount,
    String? currency,
    String? errorMessage,
  }) {
    if (success == true) {
      return PaymentResponse.success(
        paymentIntentId: paymentIntentId ?? TestConfig.testPaymentIntentId,
        clientSecret: clientSecret ?? TestConfig.testClientSecret,
        status: status ?? 'requires_payment_method',
        amount: amount ?? TestConfig.adultPrice,
        currency: currency ?? 'EUR',
      );
    } else {
      return PaymentResponse.failure(
        errorMessage: errorMessage ?? 'Test error message',
      );
    }
  }
}
