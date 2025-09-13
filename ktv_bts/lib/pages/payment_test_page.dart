import 'package:flutter/material.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../services/stripe_payment_service.dart';

class PaymentTestPage extends StatefulWidget {
  const PaymentTestPage({super.key});

  @override
  State<PaymentTestPage> createState() => _PaymentTestPageState();
}

class _PaymentTestPageState extends State<PaymentTestPage> {
  final StripePaymentService _paymentService = StripePaymentService();
  bool _isLoading = false;
  String _result = '';
  PaymentResponse? _lastResponse;

  // Hardcoded 測試參數
  final String _testCustomerName = '張三';
  final bool _testIsAdult = true;
  final String _testTime = 'Morning';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _paymentService.initialize();
      setState(() {
        _result = '✅ Stripe 服務初始化成功\n';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Stripe 服務初始化失敗: $e\n';
      });
    }
  }

  Future<void> _testCreatePaymentIntent() async {
    setState(() {
      _isLoading = true;
      _result += '\n🔄 開始測試創建支付意圖...\n';
    });

    try {
      // 創建測試支付請求
      final request = PaymentRequest(
        customerName: _testCustomerName,
        isAdult: _testIsAdult,
        time: _testTime,
        currency: 'EUR',
        description: 'KTV 測試支付 - ${_testTime} 時段',
      );

      _result += '📝 支付請求參數:\n';
      _result += '  客戶姓名: ${request.customerName}\n';
      _result += '  是否成人: ${request.isAdult}\n';
      _result += '  時段: ${request.time}\n';
      _result += '  金額: ${request.isAdult ? "20.0" : "0.0"} EUR\n';
      _result += '  貨幣: ${request.currency}\n\n';

      // 調用我們的服務
      final response = await _paymentService.createPaymentIntent(request);

      setState(() {
        _lastResponse = response;
        _result += '📊 Stripe API 響應:\n';
        _result += '  成功: ${response.success}\n';
        _result += '  支付意圖 ID: ${response.paymentIntentId ?? 'N/A'}\n';
        _result += '  客戶端密鑰: ${response.clientSecret ?? 'N/A'}\n';
        _result += '  狀態: ${response.status ?? 'N/A'}\n';
        _result += '  金額: ${response.amount ?? 'N/A'} ${response.currency ?? 'N/A'}\n';
        _result += '  錯誤訊息: ${response.errorMessage ?? 'N/A'}\n\n';

        if (response.success) {
          _result += '✅ 支付意圖創建成功！\n';
          _result += '💡 請檢查 Stripe Dashboard 確認是否收到支付意圖\n';
          _result += '🔗 Stripe Dashboard: https://dashboard.stripe.com/test/payments\n';
        } else {
          _result += '❌ 支付意圖創建失敗\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += '❌ 發生錯誤: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConfirmPayment() async {
    if (_lastResponse?.paymentIntentId == null) {
      setState(() {
        _result += '\n❌ 沒有可用的支付意圖 ID，請先創建支付意圖\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\n🔄 開始測試確認支付...\n';
    });

    try {
      // 使用測試支付方式 ID (這是 Stripe 提供的測試 ID)
      const testPaymentMethodId = 'pm_card_visa'; // Stripe 測試用 Visa 卡

      _result += '📝 確認支付參數:\n';
      _result += '  支付意圖 ID: ${_lastResponse!.paymentIntentId}\n';
      _result += '  支付方式 ID: $testPaymentMethodId\n\n';

      final response = await _paymentService.confirmPayment(
        paymentIntentId: _lastResponse!.paymentIntentId!,
        paymentMethodId: testPaymentMethodId,
      );

      setState(() {
        _result += '📊 支付確認響應:\n';
        _result += '  成功: ${response.success}\n';
        _result += '  支付意圖 ID: ${response.paymentIntentId ?? 'N/A'}\n';
        _result += '  狀態: ${response.status ?? 'N/A'}\n';
        _result += '  金額: ${response.amount ?? 'N/A'} ${response.currency ?? 'N/A'}\n';
        _result += '  錯誤訊息: ${response.errorMessage ?? 'N/A'}\n\n';

        if (response.success) {
          _result += '✅ 支付確認成功！\n';
          _result += '💰 請檢查 Stripe Dashboard 確認是否真的收到錢\n';
          _result += '🔗 Stripe Dashboard: https://dashboard.stripe.com/test/payments\n';
        } else {
          _result += '❌ 支付確認失敗\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += '❌ 發生錯誤: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetPaymentStatus() async {
    if (_lastResponse?.paymentIntentId == null) {
      setState(() {
        _result += '\n❌ 沒有可用的支付意圖 ID，請先創建支付意圖\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\n🔄 開始查詢支付狀態...\n';
    });

    try {
      final response = await _paymentService.getPaymentStatus(
        _lastResponse!.paymentIntentId!,
      );

      setState(() {
        _result += '📊 支付狀態響應:\n';
        _result += '  成功: ${response.success}\n';
        _result += '  支付意圖 ID: ${response.paymentIntentId ?? 'N/A'}\n';
        _result += '  狀態: ${response.status ?? 'N/A'}\n';
        _result += '  金額: ${response.amount ?? 'N/A'} ${response.currency ?? 'N/A'}\n';
        _result += '  錯誤訊息: ${response.errorMessage ?? 'N/A'}\n\n';

        if (response.success) {
          _result += '✅ 支付狀態查詢成功！\n';
        } else {
          _result += '❌ 支付狀態查詢失敗\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += '❌ 發生錯誤: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearResult() {
    setState(() {
      _result = '';
      _lastResponse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe 支付測試'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 測試參數顯示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 測試參數 (Hardcoded)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('客戶姓名: $_testCustomerName'),
                    Text('是否成人: ${_testIsAdult ? '是' : '否'}'),
                    Text('時段: $_testTime'),
                    Text('預期金額: ${_testIsAdult ? '20.0' : '0.0'} EUR'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 測試按鈕
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCreatePaymentIntent,
                    icon: const Icon(Icons.payment),
                    label: const Text('創建支付意圖'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConfirmPayment,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('確認支付'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testGetPaymentStatus,
                    icon: const Icon(Icons.info),
                    label: const Text('查詢狀態'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearResult,
                    icon: const Icon(Icons.clear),
                    label: const Text('清除結果'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 載入指示器
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // 結果顯示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '📋 測試結果',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      child: SingleChildScrollView(
                        child: Text(
                          _result.isEmpty ? '點擊按鈕開始測試...' : _result,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stripe Dashboard 連結
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔗 Stripe Dashboard 連結',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('測試環境: https://dashboard.stripe.com/test/payments'),
                    const Text('生產環境: https://dashboard.stripe.com/payments'),
                    const SizedBox(height: 8),
                    const Text(
                      '💡 提示: 創建支付意圖後，請到 Stripe Dashboard 檢查是否真的收到支付意圖',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
