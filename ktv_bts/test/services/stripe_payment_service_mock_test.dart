import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:ktv_bts/models/payment_request.dart';
import 'package:ktv_bts/models/payment_response.dart';
import 'package:ktv_bts/services/stripe_payment_service.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'stripe_payment_service_mock_test.mocks.dart';

void main() {
  group('StripePaymentService Mock Tests', () {
    late MockClient mockClient;
    late StripePaymentService paymentService;

    setUp(() {
      mockClient = MockClient();
      paymentService = StripePaymentService();
    });

    group('Create Payment Intent', () {
      test('should create payment intent successfully', () async {
        // Arrange
        const request = PaymentRequest(
          customerName: '張三',
          isAdult: true,
          time: 'Morning',
          amount: 20.0,
          currency: 'EUR',
        );

        final mockResponse = {
          'id': 'pi_test_123456789',
          'object': 'payment_intent',
          'amount': 2000, // Amount in cents (20 EUR)
          'currency': 'eur',
          'status': 'requires_payment_method',
          'client_secret': 'pi_test_123456789_secret_abc123',
          'metadata': {
            'customer_name': '張三',
            'is_adult': 'true',
            'time': 'Morning',
          },
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        await paymentService.initialize();
        final response = await paymentService.createPaymentIntent(request);

        // Assert
        expect(response.success, isTrue);
        expect(response.paymentIntentId, equals('pi_test_123456789'));
        expect(response.clientSecret, equals('pi_test_123456789_secret_abc123'));
        expect(response.status, equals('requires_payment_method'));
        expect(response.amount, equals(20.0));
        expect(response.currency, equals('EUR'));
      });

      test('should handle API error response', () async {
        // Arrange
        const request = PaymentRequest(
          customerName: '李小明',
          isAdult: false,
          time: 'Afternoon',
          amount: 0.0,
          currency: 'EUR',
        );

        final mockErrorResponse = {
          'error': {
            'type': 'invalid_request_error',
            'message': 'Invalid API key provided',
          },
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockErrorResponse),
          401,
        ));

        // Act
        await paymentService.initialize();
        final response = await paymentService.createPaymentIntent(request);

        // Assert
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Invalid API key provided'));
        expect(response.paymentIntentId, isNull);
      });

      test('should handle network error', () async {
        // Arrange
        const request = PaymentRequest(
          customerName: '王大明',
          isAdult: true,
          time: 'Morning',
          amount: 20.0,
          currency: 'EUR',
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(Exception('Network error'));

        // Act
        await paymentService.initialize();
        final response = await paymentService.createPaymentIntent(request);

        // Assert
        expect(response.success, isFalse);
        expect(response.errorMessage, contains('Network error'));
      });
    });

    group('Confirm Payment', () {
      test('should confirm payment successfully', () async {
        // Arrange
        const paymentIntentId = 'pi_test_123456789';
        const paymentMethodId = 'pm_card_visa';

        final mockResponse = {
          'id': paymentIntentId,
          'object': 'payment_intent',
          'amount': 2000, // 20 EUR in cents
          'currency': 'eur',
          'status': 'succeeded',
          'client_secret': '${paymentIntentId}_secret_abc123',
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        await paymentService.initialize();
        final response = await paymentService.confirmPayment(
          paymentIntentId: paymentIntentId,
          paymentMethodId: paymentMethodId,
        );

        // Assert
        expect(response.success, isTrue);
        expect(response.paymentIntentId, equals(paymentIntentId));
        expect(response.status, equals('succeeded'));
        expect(response.amount, equals(20.0));
        expect(response.currency, equals('EUR'));
      });

      test('should handle payment confirmation failure', () async {
        // Arrange
        const paymentIntentId = 'pi_test_123456789';
        const paymentMethodId = 'pm_card_declined';

        final mockErrorResponse = {
          'error': {
            'type': 'card_error',
            'message': 'Your card was declined.',
          },
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockErrorResponse),
          402,
        ));

        // Act
        await paymentService.initialize();
        final response = await paymentService.confirmPayment(
          paymentIntentId: paymentIntentId,
          paymentMethodId: paymentMethodId,
        );

        // Assert
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Your card was declined.'));
      });
    });

    group('Cancel Payment', () {
      test('should cancel payment successfully', () async {
        // Arrange
        const paymentIntentId = 'pi_test_123456789';

        final mockResponse = {
          'id': paymentIntentId,
          'object': 'payment_intent',
          'amount': 2000, // 20 EUR in cents
          'currency': 'eur',
          'status': 'canceled',
          'client_secret': '${paymentIntentId}_secret_abc123',
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        await paymentService.initialize();
        final response = await paymentService.cancelPayment(paymentIntentId);

        // Assert
        expect(response.success, isTrue);
        expect(response.paymentIntentId, equals(paymentIntentId));
        expect(response.status, equals('canceled'));
      });
    });

    group('Get Payment Status', () {
      test('should get payment status successfully', () async {
        // Arrange
        const paymentIntentId = 'pi_test_123456789';

        final mockResponse = {
          'id': paymentIntentId,
          'object': 'payment_intent',
          'amount': 2000, // 20 EUR in cents
          'currency': 'eur',
          'status': 'requires_confirmation',
          'client_secret': '${paymentIntentId}_secret_abc123',
        };

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        await paymentService.initialize();
        final response = await paymentService.getPaymentStatus(paymentIntentId);

        // Assert
        expect(response.success, isTrue);
        expect(response.paymentIntentId, equals(paymentIntentId));
        expect(response.status, equals('requires_confirmation'));
        expect(response.amount, equals(20.0));
        expect(response.currency, equals('EUR'));
      });

      test('should handle payment not found', () async {
        // Arrange
        const paymentIntentId = 'pi_invalid_id';

        final mockErrorResponse = {
          'error': {
            'type': 'invalid_request_error',
            'message': 'No such payment_intent: pi_invalid_id',
          },
        };

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockErrorResponse),
          404,
        ));

        // Act
        await paymentService.initialize();
        final response = await paymentService.getPaymentStatus(paymentIntentId);

        // Assert
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('No such payment_intent: pi_invalid_id'));
      });
    });
  });
}
