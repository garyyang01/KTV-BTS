import 'dart:io';
import 'lib/models/payment_request.dart';
import 'lib/models/payment_response.dart';
import 'lib/services/stripe_payment_service.dart';

void main() async {
  print('🧪 開始測試 Stripe 支付服務...\n');
  
  try {
    // 初始化服務
    final paymentService = StripePaymentService();
    await paymentService.initialize();
    print('✅ Stripe 服務初始化成功\n');
    
    // 創建測試支付請求
    final request = PaymentRequest(
      customerName: '張三',
      isAdult: true,
      time: 'Morning',
      currency: 'EUR',
      description: 'KTV 測試支付 - Morning 時段',
    );
    
    print('📝 支付請求參數:');
    print('  客戶姓名: ${request.customerName}');
    print('  是否成人: ${request.isAdult}');
    print('  時段: ${request.time}');
    print('  金額: ${request.isAdult ? "20.0" : "0.0"} EUR');
    print('  貨幣: ${request.currency}');
    print('  描述: ${request.description}\n');
    
    // 創建支付意圖
    print('🔄 創建支付意圖...');
    final response = await paymentService.createPaymentIntent(request);
    
    print('📊 Stripe API 響應:');
    print('  成功: ${response.success}');
    print('  支付意圖 ID: ${response.paymentIntentId ?? 'N/A'}');
    print('  客戶端密鑰: ${response.clientSecret ?? 'N/A'}');
    print('  狀態: ${response.status ?? 'N/A'}');
    print('  金額: ${response.amount ?? 'N/A'} ${response.currency ?? 'N/A'}');
    print('  錯誤訊息: ${response.errorMessage ?? 'N/A'}\n');
    
    if (response.success) {
      print('✅ 支付意圖創建成功！');
      print('💡 請檢查 Stripe Dashboard 確認是否收到支付意圖');
      print('🔗 Stripe Dashboard: https://dashboard.stripe.com/test/payments\n');
      
      // 測試確認支付
      print('🔄 測試確認支付...');
      const testPaymentMethodId = 'pm_card_visa'; // Stripe 測試用 Visa 卡
      
      final confirmResponse = await paymentService.confirmPayment(
        paymentIntentId: response.paymentIntentId!,
        paymentMethodId: testPaymentMethodId,
      );
      
      print('📊 支付確認響應:');
      print('  成功: ${confirmResponse.success}');
      print('  支付意圖 ID: ${confirmResponse.paymentIntentId ?? 'N/A'}');
      print('  狀態: ${confirmResponse.status ?? 'N/A'}');
      print('  金額: ${confirmResponse.amount ?? 'N/A'} ${confirmResponse.currency ?? 'N/A'}');
      print('  錯誤訊息: ${confirmResponse.errorMessage ?? 'N/A'}\n');
      
      if (confirmResponse.success) {
        print('✅ 支付確認成功！');
        print('💰 請檢查 Stripe Dashboard 確認是否真的收到錢');
        print('🔗 Stripe Dashboard: https://dashboard.stripe.com/test/payments\n');
      } else {
        print('❌ 支付確認失敗');
      }
      
      // 測試查詢支付狀態
      print('🔄 查詢支付狀態...');
      final statusResponse = await paymentService.getPaymentStatus(
        response.paymentIntentId!,
      );
      
      print('📊 支付狀態響應:');
      print('  成功: ${statusResponse.success}');
      print('  支付意圖 ID: ${statusResponse.paymentIntentId ?? 'N/A'}');
      print('  狀態: ${statusResponse.status ?? 'N/A'}');
      print('  金額: ${statusResponse.amount ?? 'N/A'} ${statusResponse.currency ?? 'N/A'}');
      print('  錯誤訊息: ${statusResponse.errorMessage ?? 'N/A'}\n');
      
      if (statusResponse.success) {
        print('✅ 支付狀態查詢成功！');
      } else {
        print('❌ 支付狀態查詢失敗');
      }
      
    } else {
      print('❌ 支付意圖創建失敗');
    }
    
  } catch (e) {
    print('❌ 發生錯誤: $e');
  }
  
  print('\n🎉 測試完成！');
}
