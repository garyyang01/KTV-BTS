import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/stripe_payment_service.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';

class PaymentPage extends StatefulWidget {
  final PaymentRequest paymentRequest;

  const PaymentPage({
    super.key,
    required this.paymentRequest,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _stripeService = StripePaymentService();
  
  // 表單控制器
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  
  bool _isLoading = false;
  PaymentResponse? _lastPaymentIntent;

  @override
  void initState() {
    super.initState();
    _initializeService();
    // 自動創建支付意圖
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createPaymentIntent();
    });
  }

  Future<void> _initializeService() async {
    try {
      await _stripeService.initialize();
    } catch (e) {
      // 靜默處理初始化錯誤，在支付時會再次嘗試
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvcController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _createPaymentIntent() async {
    if (_lastPaymentIntent != null) return;

    try {
      final response = await _stripeService.createPaymentIntent(widget.paymentRequest);
      setState(() {
        _lastPaymentIntent = response;
      });
    } catch (e) {
      // 靜默處理錯誤，在支付時會再次嘗試
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lastPaymentIntent == null || !_lastPaymentIntent!.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先創建支付意圖'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用測試卡號創建 PaymentMethod
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiryParts = _expiryDateController.text.split('/');
      final month = expiryParts[0];
      final year = '20${expiryParts[1]}';
      final cvc = _cvcController.text;

      // 創建 PaymentMethod
      final paymentMethodResponse = await _createPaymentMethod(
        cardNumber: cardNumber,
        expMonth: int.parse(month),
        expYear: int.parse(year),
        cvc: cvc,
        cardholderName: _cardholderNameController.text,
      );

      if (!paymentMethodResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('支付處理失敗: ${paymentMethodResponse.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 確認支付
      final response = await _stripeService.confirmPayment(
        paymentIntentId: _lastPaymentIntent!.paymentIntentId!,
        paymentMethodId: paymentMethodResponse.paymentIntentId!,
      );

      if (response.success) {
        // 支付成功，顯示成功頁面或返回主頁
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('支付失敗: ${response.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('支付處理錯誤: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<PaymentResponse> _createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      final response = await _stripeService.createPaymentMethod(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
      );
      return response;
    } catch (e) {
      return PaymentResponse.failure(errorMessage: '創建支付方法失敗: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('支付成功！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('客戶: ${widget.paymentRequest.customerName}'),
            Text('票種: ${widget.paymentRequest.isAdult ? '成人票' : '兒童票'}'),
            Text('時段: ${widget.paymentRequest.time}'),
            Text('金額: ${widget.paymentRequest.isAdult ? '19.0' : '0.0'} EUR'),
            const SizedBox(height: 16),
            const Text(
              '您的門票已成功購買！\n請保留此收據作為入場憑證。',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 關閉對話框
              Navigator.of(context).pop(); // 返回上一頁
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String input) {
    // 移除所有非數字字符
    String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    
    // 限制長度為16位
    if (digitsOnly.length > 16) {
      digitsOnly = digitsOnly.substring(0, 16);
    }
    
    // 每4位數字添加空格
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }
    
    return formatted;
  }

  String _formatExpiryDate(String input) {
    // 移除所有非數字字符
    String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    
    // 限制長度為4位
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }
    
    // 在月份和年份之間添加斜杠
    if (digitsOnly.length >= 2) {
      return '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2)}';
    }
    
    return digitsOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付頁面'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 訂單摘要
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 訂單摘要',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('客戶姓名: ${widget.paymentRequest.customerName}'),
                    Text('票種: ${widget.paymentRequest.isAdult ? '成人票' : '兒童票'}'),
                    Text('時段: ${widget.paymentRequest.time}'),
                    Text('金額: ${widget.paymentRequest.isAdult ? '19.0' : '0.0'} EUR'),
                    Text('描述: ${widget.paymentRequest.description}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 支付表單
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💳 支付資訊',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 持卡人姓名
                      TextFormField(
                        controller: _cardholderNameController,
                        decoration: const InputDecoration(
                          labelText: '持卡人姓名',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '請輸入持卡人姓名';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 卡號
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19), // 16位數字 + 3個空格
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final formatted = _formatCardNumber(newValue.text);
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: '卡號',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: '4242 4242 4242 4242',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '請輸入卡號';
                          }
                          String digitsOnly = value.replaceAll(' ', '');
                          if (digitsOnly.length != 16) {
                            return '卡號必須為16位數字';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 到期日和CVC
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _expiryDateController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  final formatted = _formatExpiryDate(newValue.text);
                                  return TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }),
                              ],
                              decoration: const InputDecoration(
                                labelText: '到期日',
                                border: OutlineInputBorder(),
                                hintText: '12/25',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '請輸入到期日';
                                }
                                if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                  return '格式: MM/YY';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _cvcController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'CVC',
                                border: OutlineInputBorder(),
                                hintText: '123',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '請輸入CVC';
                                }
                                if (value.length < 3 || value.length > 4) {
                                  return 'CVC必須為3-4位數字';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 支付按鈕
                      ElevatedButton(
                        onPressed: _isLoading ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('處理中...'),
                                ],
                              )
                            : const Text(
                                '💳 立即支付',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
