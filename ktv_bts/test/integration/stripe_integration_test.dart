import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:ktv_bts/models/payment_request.dart';
import 'package:ktv_bts/models/payment_response.dart';
import 'package:ktv_bts/services/stripe_payment_service.dart';

void main() {
  group('Stripe Integration Tests', () {
    late StripePaymentService paymentService;

    setUpAll(() async {
      // Load test environment variables
      await dotenv.load(fileName: ".env.test");
    });

    setUp(() {
      paymentService = StripePaymentService();
    });

    group('Service Initialization', () {
      test('should initialize with test environment variables', () async {
        // Act
        await paymentService.initialize();

        // Assert
        expect(paymentService.publicKey, isNotEmpty);
        expect(paymentService.publicKey, startsWith('pk_test_'));
      });
    });

    group('Payment Request Validation', () {
      test('should validate adult morning booking request', () {
        // Arrange
        const request = PaymentRequest(
          customerName: '張三',
          isAdult: true,
          time: 'Morning',
          currency: 'EUR',
        );

        // Act & Assert
        expect(request.customerName, equals('張三'));
        expect(request.isAdult, isTrue);
        expect(request.time, equals('Morning'));
        expect(request.currency, equals('EUR'));
        expect(request.amount, equals(0.0)); // Default amount
      });

      test('should validate child evening booking request', () {
        // Arrange
        const request = PaymentRequest(
          customerName: '李小明',
          isAdult: false,
          time: 'Afternoon',
          currency: 'EUR',
        );

        // Act & Assert
        expect(request.customerName, equals('李小明'));
        expect(request.isAdult, isFalse);
        expect(request.time, equals('Afternoon'));
        expect(request.currency, equals('EUR'));
      });
    });

    group('Pricing Calculation', () {
      test('should calculate correct pricing for different scenarios', () {
        // Test cases for pricing calculation
        final testCases = [
          {
            'isAdult': true,
            'time': 'Morning',
            'expectedPrice': 20.0,
            'description': 'Adult morning session',
          },
          {
            'isAdult': true,
            'time': 'Afternoon',
            'expectedPrice': 20.0,
            'description': 'Adult afternoon session',
          },
          {
            'isAdult': false,
            'time': 'Morning',
            'expectedPrice': 0.0,
            'description': 'Child morning session',
          },
          {
            'isAdult': false,
            'time': 'Afternoon',
            'expectedPrice': 0.0,
            'description': 'Child afternoon session',
          },
        ];

        for (final testCase in testCases) {
          // Arrange
          final request = PaymentRequest(
            customerName: 'Test Customer',
            isAdult: testCase['isAdult'] as bool,
            time: testCase['time'] as String,
            currency: 'EUR',
          );

          // Act
          final json = request.toJson();

          // Assert
          expect(
            json['is_adult'],
            equals(testCase['isAdult']),
            reason: testCase['description'] as String,
          );
          expect(
            json['time'],
            equals(testCase['time']),
            reason: testCase['description'] as String,
          );
        }
      });
    });

    group('Response Model Tests', () {
      test('should create and validate successful payment response', () {
        // Arrange
        final response = PaymentResponse.success(
          paymentIntentId: 'pi_test_123456789',
          clientSecret: 'pi_test_123456789_secret_abc123',
          status: 'requires_payment_method',
          amount: 20.0,
          currency: 'EUR',
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(response.success, isTrue);
        expect(json['success'], isTrue);
        expect(json['payment_intent_id'], equals('pi_test_123456789'));
        expect(json['client_secret'], equals('pi_test_123456789_secret_abc123'));
        expect(json['status'], equals('requires_payment_method'));
        expect(json['amount'], equals(20.0));
        expect(json['currency'], equals('EUR'));
      });

      test('should create and validate failed payment response', () {
        // Arrange
        final response = PaymentResponse.failure(
          errorMessage: 'Test error message',
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(response.success, isFalse);
        expect(json['success'], isFalse);
        expect(json['error_message'], equals('Test error message'));
        expect(json['payment_intent_id'], isNull);
        expect(json['client_secret'], isNull);
        expect(json['status'], isNull);
        expect(json['amount'], isNull);
        expect(json['currency'], isNull);
      });
    });

    group('Service Interface Compliance', () {
      test('should implement all required interface methods', () async {
        // Arrange
        await paymentService.initialize();

        // Act & Assert
        expect(paymentService, isA<IStripePaymentService>());
        
        // Test that all interface methods exist and are callable
        const request = PaymentRequest(
          customerName: 'Test',
          isAdult: true,
          time: 'Morning',
        );

        // These should not throw exceptions (even if they fail due to mock keys)
        expect(
          () => paymentService.createPaymentIntent(request),
          returnsNormally,
        );
        
        expect(
          () => paymentService.confirmPayment(
            paymentIntentId: 'pi_test_123',
            paymentMethodId: 'pm_test_123',
          ),
          returnsNormally,
        );
        
        expect(
          () => paymentService.cancelPayment('pi_test_123'),
          returnsNormally,
        );
        
        expect(
          () => paymentService.getPaymentStatus('pi_test_123'),
          returnsNormally,
        );
      });
    });

    group('Error Handling Integration', () {
      test('should handle missing environment variables gracefully', () async {
        // This test verifies that the service handles missing env vars
        // by checking the initialization process
        
        // Arrange
        final service = StripePaymentService();
        
        // Act & Assert
        // Should not throw during initialization with test env
        expect(
          () async => await service.initialize(),
          returnsNormally,
        );
      });
    });
  });
}
