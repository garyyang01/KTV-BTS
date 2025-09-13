import '../models/payment_request.dart';
import '../services/stripe_payment_service.dart';

/// Example usage of Stripe payment service for KTV booking
class PaymentExample {
  final IStripePaymentService _paymentService = StripePaymentService();

  /// Example: Create a payment for adult morning session
  Future<void> exampleAdultMorningBooking() async {
    try {
      // Initialize the service (this will load environment variables)
      await _paymentService.initialize();

      // Create payment request
      final paymentRequest = PaymentRequest(
        customerName: '張三',
        isAdult: true,
        time: 'Morning',
        amount: 20.0, // Will be calculated automatically (20 EUR for adults)
        currency: 'EUR',
        description: 'KTV Morning Session for Adult',
      );

      // Create payment intent
      final response = await _paymentService.createPaymentIntent(paymentRequest);

      if (response.success) {
        print('Payment intent created successfully!');
        print('Payment Intent ID: ${response.paymentIntentId}');
        print('Client Secret: ${response.clientSecret}');
        print('Amount: ${response.amount} ${response.currency}');
        
        // Here you would typically:
        // 1. Show payment form to user
        // 2. Collect payment method
        // 3. Confirm payment
        // 4. Handle success/failure
        
      } else {
        print('Payment failed: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Example: Create a payment for child evening session
  Future<void> exampleChildEveningBooking() async {
    try {
      await _paymentService.initialize();

      final paymentRequest = PaymentRequest(
        customerName: '李小明',
        isAdult: false,
        time: 'Afternoon',
        amount: 0.0, // Will be calculated automatically (0 EUR for children)
        currency: 'EUR',
        description: 'KTV Afternoon Session for Child',
      );

      final response = await _paymentService.createPaymentIntent(paymentRequest);

      if (response.success) {
        print('Child evening booking payment intent created!');
        print('Payment Intent ID: ${response.paymentIntentId}');
        print('Amount: ${response.amount} ${response.currency}');
      } else {
        print('Payment failed: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Example: Complete payment flow
  Future<void> completePaymentFlow() async {
    try {
      await _paymentService.initialize();

      // Step 1: Create payment intent
      final paymentRequest = PaymentRequest(
        customerName: '王大明',
        isAdult: true,
        time: 'Afternoon',
        currency: 'EUR',
      );

      final createResponse = await _paymentService.createPaymentIntent(paymentRequest);

      if (!createResponse.success) {
        print('Failed to create payment intent: ${createResponse.errorMessage}');
        return;
      }

      print('Payment intent created: ${createResponse.paymentIntentId}');

      // Step 2: Simulate payment method collection and confirmation
      // In real app, you would collect payment method from user
      final paymentMethodId = 'pm_card_visa'; // This would come from Stripe Elements

      final confirmResponse = await _paymentService.confirmPayment(
        paymentIntentId: createResponse.paymentIntentId!,
        paymentMethodId: paymentMethodId,
      );

      if (confirmResponse.success) {
        print('Payment confirmed successfully!');
        print('Status: ${confirmResponse.status}');
        print('Amount: ${confirmResponse.amount} ${confirmResponse.currency}');
      } else {
        print('Payment confirmation failed: ${confirmResponse.errorMessage}');
      }

    } catch (e) {
      print('Error in payment flow: $e');
    }
  }

  /// Example: Check payment status
  Future<void> checkPaymentStatus(String paymentIntentId) async {
    try {
      await _paymentService.initialize();

      final response = await _paymentService.getPaymentStatus(paymentIntentId);

      if (response.success) {
        print('Payment Status: ${response.status}');
        print('Amount: ${response.amount} ${response.currency}');
      } else {
        print('Failed to get payment status: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  /// Example: Cancel payment
  Future<void> cancelPayment(String paymentIntentId) async {
    try {
      await _paymentService.initialize();

      final response = await _paymentService.cancelPayment(paymentIntentId);

      if (response.success) {
        print('Payment cancelled successfully!');
        print('Status: ${response.status}');
      } else {
        print('Failed to cancel payment: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error cancelling payment: $e');
    }
  }
}
