import 'package:flutter_test/flutter_test.dart';
import 'package:ktv_bts/models/payment_request.dart';
import 'package:ktv_bts/models/payment_response.dart';

void main() {
  group('API Output Format Demo', () {
    test('should demonstrate successful payment response format', () {
      // Arrange - 模擬成功的支付響應
      final response = PaymentResponse.success(
        paymentIntentId: 'pi_test_123456789',
        clientSecret: 'pi_test_123456789_secret_abc123',
        status: 'requires_payment_method',
        amount: 20.0,
        currency: 'EUR',
      );

      // Act - 轉換為 JSON 格式
      final jsonOutput = response.toJson();

      // Assert - 驗證輸出格式
      print('\n=== 成功支付響應格式 (Success Response Format) ===');
      print('JSON Output:');
      print('{');
      print('  "success": ${jsonOutput['success']},');
      print('  "payment_intent_id": "${jsonOutput['payment_intent_id']}",');
      print('  "client_secret": "${jsonOutput['client_secret']}",');
      print('  "status": "${jsonOutput['status']}",');
      print('  "amount": ${jsonOutput['amount']},');
      print('  "currency": "${jsonOutput['currency']}",');
      print('  "error_message": ${jsonOutput['error_message']}');
      print('}');

      // 驗證欄位
      expect(jsonOutput['success'], isTrue);
      expect(jsonOutput['payment_intent_id'], equals('pi_test_123456789'));
      expect(jsonOutput['client_secret'], equals('pi_test_123456789_secret_abc123'));
      expect(jsonOutput['status'], equals('requires_payment_method'));
      expect(jsonOutput['amount'], equals(20.0));
      expect(jsonOutput['currency'], equals('EUR'));
      expect(jsonOutput['error_message'], isNull);
    });

    test('should demonstrate failed payment response format', () {
      // Arrange - 模擬失敗的支付響應
      final response = PaymentResponse.failure(
        errorMessage: 'Invalid API key provided',
      );

      // Act - 轉換為 JSON 格式
      final jsonOutput = response.toJson();

      // Assert - 驗證輸出格式
      print('\n=== 失敗支付響應格式 (Failure Response Format) ===');
      print('JSON Output:');
      print('{');
      print('  "success": ${jsonOutput['success']},');
      print('  "payment_intent_id": ${jsonOutput['payment_intent_id']},');
      print('  "client_secret": ${jsonOutput['client_secret']},');
      print('  "status": ${jsonOutput['status']},');
      print('  "amount": ${jsonOutput['amount']},');
      print('  "currency": ${jsonOutput['currency']},');
      print('  "error_message": "${jsonOutput['error_message']}"');
      print('}');

      // 驗證欄位
      expect(jsonOutput['success'], isFalse);
      expect(jsonOutput['payment_intent_id'], isNull);
      expect(jsonOutput['client_secret'], isNull);
      expect(jsonOutput['status'], isNull);
      expect(jsonOutput['amount'], isNull);
      expect(jsonOutput['currency'], isNull);
      expect(jsonOutput['error_message'], equals('Invalid API key provided'));
    });

    test('should demonstrate different payment statuses', () {
      // 測試不同的支付狀態
      final statuses = [
        'requires_payment_method',
        'requires_confirmation',
        'requires_action',
        'processing',
        'succeeded',
        'canceled',
      ];

      print('\n=== 支付狀態說明 (Payment Status Descriptions) ===');
      for (final status in statuses) {
        final response = PaymentResponse.success(
          paymentIntentId: 'pi_test_123456789',
          clientSecret: 'pi_test_123456789_secret_abc123',
          status: status,
          amount: 20.0,
          currency: 'EUR',
        );

        final jsonOutput = response.toJson();
        print('Status: "${jsonOutput['status']}"');
        
        // 驗證狀態
        expect(jsonOutput['status'], equals(status));
      }
    });

    test('should demonstrate pricing calculation output', () {
      print('\n=== 定價計算輸出 (Pricing Calculation Output) ===');
      
      // 成人支付
      final adultRequest = const PaymentRequest(
        customerName: '張三',
        isAdult: true,
        time: 'Morning',
        currency: 'EUR',
      );

      final adultResponse = PaymentResponse.success(
        paymentIntentId: 'pi_adult_123456789',
        clientSecret: 'pi_adult_123456789_secret_abc123',
        status: 'requires_payment_method',
        amount: 20.0, // 成人固定 20 歐元
        currency: 'EUR',
      );

      print('成人支付 (Adult Payment):');
      print('Input: ${adultRequest.toJson()}');
      print('Output: ${adultResponse.toJson()}');

      // 兒童支付
      final childRequest = const PaymentRequest(
        customerName: '李小明',
        isAdult: false,
        time: 'Afternoon',
        currency: 'EUR',
      );

      final childResponse = PaymentResponse.success(
        paymentIntentId: 'pi_child_123456789',
        clientSecret: 'pi_child_123456789_secret_abc123',
        status: 'requires_payment_method',
        amount: 0.0, // 兒童免費
        currency: 'EUR',
      );

      print('\n兒童支付 (Child Payment):');
      print('Input: ${childRequest.toJson()}');
      print('Output: ${childResponse.toJson()}');

      // 驗證定價
      expect(adultResponse.amount, equals(20.0));
      expect(childResponse.amount, equals(0.0));
    });

    test('should demonstrate error handling output', () {
      print('\n=== 錯誤處理輸出 (Error Handling Output) ===');
      
      final errorTypes = [
        'Invalid API key provided',
        'Network error: Connection timeout',
        'Your card was declined.',
        'No such payment_intent: pi_invalid_id',
        'Payment amount must be greater than 0',
      ];

      for (final errorMessage in errorTypes) {
        final response = PaymentResponse.failure(
          errorMessage: errorMessage,
        );

        final jsonOutput = response.toJson();
        print('Error: "${jsonOutput['error_message']}"');
        print('Response: ${jsonOutput}');
        print('');

        // 驗證錯誤響應
        expect(jsonOutput['success'], isFalse);
        expect(jsonOutput['error_message'], equals(errorMessage));
        expect(jsonOutput['payment_intent_id'], isNull);
      }
    });
  });
}
