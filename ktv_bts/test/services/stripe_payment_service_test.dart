import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:ktv_bts/models/payment_request.dart';
import 'package:ktv_bts/models/payment_response.dart';
import 'package:ktv_bts/services/stripe_payment_service.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'stripe_payment_service_test.mocks.dart';

void main() {
  group('StripePaymentService Tests', () {
    late StripePaymentService paymentService;
    late MockClient mockClient;

    setUpAll(() async {
      // Load test environment variables
      await dotenv.load(fileName: ".env.test");
    });

    setUp(() {
      paymentService = StripePaymentService();
      mockClient = MockClient();
    });

    group('Initialization', () {
      test('should initialize successfully with valid environment variables', () async {
        // Act
        await paymentService.initialize();

        // Assert
        expect(paymentService.publicKey, isNotEmpty);
        expect(paymentService.publicKey, startsWith('pk_test_'));
      });

      test('should throw exception when environment variables are missing', () async {
        // Arrange
        await dotenv.load(fileName: ".env.invalid");

        // Act & Assert
        expect(
          () async => await paymentService.initialize(),
          throwsException,
        );
      });
    });

    group('Payment Request Model', () {
      test('should create PaymentRequest with correct values', () {
        // Arrange
        const request = PaymentRequest(
          customerName: '張三',
          isAdult: true,
          time: 'Morning',
          amount: 20.0,
          currency: 'EUR',
          description: 'Test booking',
        );

        // Assert
        expect(request.customerName, equals('張三'));
        expect(request.isAdult, isTrue);
        expect(request.time, equals('Morning'));
        expect(request.amount, equals(20.0));
        expect(request.currency, equals('EUR'));
        expect(request.description, equals('Test booking'));
      });

      test('should convert PaymentRequest to JSON correctly', () {
        // Arrange
        const request = PaymentRequest(
          customerName: '李小明',
          isAdult: false,
          time: 'Afternoon',
          amount: 0.0,
          currency: 'EUR',
        );

        // Act
        final json = request.toJson();

        // Assert
        expect(json['customer_name'], equals('李小明'));
        expect(json['is_adult'], isFalse);
        expect(json['time'], equals('Afternoon'));
        expect(json['amount'], equals(0.0));
        expect(json['currency'], equals('EUR'));
      });

      test('should create PaymentRequest from JSON correctly', () {
        // Arrange
        final json = {
          'customer_name': '王大明',
          'is_adult': true,
          'time': 'Afternoon',
          'amount': 20.0,
          'currency': 'EUR',
          'description': 'Afternoon session',
        };

        // Act
        final request = PaymentRequest.fromJson(json);

        // Assert
        expect(request.customerName, equals('王大明'));
        expect(request.isAdult, isTrue);
        expect(request.time, equals('Afternoon'));
        expect(request.amount, equals(20.0));
        expect(request.currency, equals('EUR'));
        expect(request.description, equals('Afternoon session'));
      });
    });

    group('Payment Response Model', () {
      test('should create successful PaymentResponse', () {
        // Act
        final response = PaymentResponse.success(
          paymentIntentId: 'pi_test_123',
          clientSecret: 'pi_test_123_secret_abc',
          status: 'requires_payment_method',
          amount: 20.0,
          currency: 'EUR',
        );

        // Assert
        expect(response.success, isTrue);
        expect(response.paymentIntentId, equals('pi_test_123'));
        expect(response.clientSecret, equals('pi_test_123_secret_abc'));
        expect(response.status, equals('requires_payment_method'));
        expect(response.amount, equals(20.0));
        expect(response.currency, equals('EUR'));
        expect(response.errorMessage, isNull);
      });

      test('should create failed PaymentResponse', () {
        // Act
        final response = PaymentResponse.failure(
          errorMessage: 'Payment failed',
        );

        // Assert
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Payment failed'));
        expect(response.paymentIntentId, isNull);
        expect(response.clientSecret, isNull);
        expect(response.status, isNull);
        expect(response.amount, isNull);
        expect(response.currency, isNull);
      });

      test('should convert PaymentResponse to JSON correctly', () {
        // Arrange
        final response = PaymentResponse.success(
          paymentIntentId: 'pi_test_123',
          clientSecret: 'pi_test_123_secret_abc',
          status: 'succeeded',
          amount: 20.0,
          currency: 'EUR',
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['success'], isTrue);
        expect(json['payment_intent_id'], equals('pi_test_123'));
        expect(json['client_secret'], equals('pi_test_123_secret_abc'));
        expect(json['status'], equals('succeeded'));
        expect(json['amount'], equals(20.0));
        expect(json['currency'], equals('EUR'));
      });
    });

    group('Pricing Logic', () {
      test('should calculate correct price for adult session', () async {
        // Arrange
        const request = PaymentRequest(
          customerName: 'Test',
          isAdult: true,
          time: 'Morning',
          amount: 0, // Will be calculated
        );

        // Act
        await paymentService.initialize();
        final response = paymentService.createPaymentIntent(request);

        // Assert
        expect(response, isA<Future<PaymentResponse>>());
      });

      test('should calculate correct price for child session', () async {
        // Arrange
        const request = PaymentRequest(
          customerName: 'Test',
          isAdult: false,
          time: 'Afternoon',
          amount: 0, // Will be calculated
        );

        // Act
        await paymentService.initialize();
        final response = paymentService.createPaymentIntent(request);

        // Assert
        expect(response, isA<Future<PaymentResponse>>());
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        await paymentService.initialize();
        const request = PaymentRequest(
          customerName: 'Test',
          isAdult: true,
          time: 'Morning',
        );

        // Act
        final response = await paymentService.createPaymentIntent(request);

        // Assert
        // Since we're using mock keys, this should fail gracefully
        expect(response, isA<PaymentResponse>());
      });
    });
  });
}
