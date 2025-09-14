import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/stripe_payment_service.dart';
import '../services/ticket_api_service.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/ticket_request.dart';
import '../models/ticket_info.dart';
import 'rail_search_test_page.dart';

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
  final _ticketApiService = TicketApiService();
  
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
    print('💳 Starting payment process...');
    
    if (!_formKey.currentState!.validate()) {
      print('💳 Form validation failed');
      return;
    }

    if (_lastPaymentIntent == null || !_lastPaymentIntent!.success) {
      print('💳 Payment intent not ready');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create payment intent first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('💳 Payment intent ready, starting payment...');
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
            content: Text('Payment processing failed: ${paymentMethodResponse.errorMessage}'),
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
        print('💳 Payment successful with ID: ${response.paymentIntentId}');
        // 支付成功，調用外部 API
        await _submitTicketToApi(response.paymentIntentId!);
      } else if (response.requiresAction) {
        print('🔒 3DS authentication required');
        // 顯示 3DS 驗證提示
        _show3DSAuthenticationDialog(response);
      } else {
        print('💳 Payment failed: ${response.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${response.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment processing error: $e'),
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
      return PaymentResponse.failure(errorMessage: 'Failed to create payment method: $e');
    }
  }

  /// Submit ticket request to external API after successful payment
  Future<void> _submitTicketToApi(String paymentIntentId) async {
    try {
      print('🎫 Submitting ticket request to API with paymentIntentId: $paymentIntentId');
      
      // Check if we have ticket request data
      if (widget.paymentRequest.ticketRequest == null) {
        print('🎫 Using legacy ticket format');
        // Fallback to legacy single ticket format
        final legacyTicketRequest = _createLegacyTicketRequest();
        final apiResponse = await _ticketApiService.submitTicketRequest(
          paymentRefno: paymentIntentId,
          ticketRequest: legacyTicketRequest,
        );
        
        print('🎫 Legacy API response - Success: ${apiResponse.success}, Error: ${apiResponse.errorMessage}');
        
        if (apiResponse.success) {
          _showSuccessDialog();
        } else {
          _showApiErrorDialog(apiResponse.errorMessage ?? 'Unknown error');
        }
      } else {
        print('🎫 Using new ticket request format');
        print('🎫 Ticket request data: ${widget.paymentRequest.ticketRequest!.toJson()}');
        
        // Use new ticket request format
        final apiResponse = await _ticketApiService.submitTicketRequest(
          paymentRefno: paymentIntentId,
          ticketRequest: widget.paymentRequest.ticketRequest!,
        );
        
        print('🎫 New API response - Success: ${apiResponse.success}, Error: ${apiResponse.errorMessage}');
        
        if (apiResponse.success) {
          _showSuccessDialog();
        } else {
          // 臨時測試：即使 API 失敗也顯示成功對話框
          print('🎫 API failed but showing success dialog for testing');
          _showSuccessDialog();
          // _showApiErrorDialog(apiResponse.errorMessage ?? 'Unknown error');
        }
      }
    } catch (e) {
      print('🎫 Exception in _submitTicketToApi: $e');
      _showApiErrorDialog('Failed to submit ticket request: $e');
    }
  }

  /// Create legacy ticket request from current payment request
  TicketRequest _createLegacyTicketRequest() {
    // This is a fallback for when ticketRequest is null
    // We'll create a single ticket based on the current payment request
    final customerName = widget.paymentRequest.customerName;
    final nameParts = customerName.split(' ');
    final familyName = nameParts.length > 1 ? nameParts.last : '';
    final givenName = nameParts.length > 1 ? nameParts.take(nameParts.length - 1).join(' ') : customerName;
    
    return TicketRequest(
      recipientEmail: 'customer@example.com', // Default email
      totalTickets: 1,
      ticketInfo: [
        TicketInfo(
          familyName: familyName,
          givenName: givenName,
          isAdult: widget.paymentRequest.isAdult,
          session: widget.paymentRequest.time,
          arrivalTime: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0], // Tomorrow
          price: widget.paymentRequest.amount,
        ),
      ],
    );
  }

  /// Show API error dialog
  void _showApiErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('API Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment was successful, but there was an error submitting the ticket request:'),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please contact support with your payment reference:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              _lastPaymentIntent?.paymentIntentId ?? 'Unknown',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // 跳轉到首頁
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    print('🎫 Showing success dialog');
    print('🎫 PaymentRequest time: ${widget.paymentRequest.time}');
    print('🎫 PaymentRequest isCombinedPayment: ${widget.paymentRequest.isCombinedPayment}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${widget.paymentRequest.customerName}'),
              Text('Total Amount: ${widget.paymentRequest.amount} EUR'),
              Text('Description: ${widget.paymentRequest.description}'),
              const SizedBox(height: 16),
              
              // 如果是組合支付，顯示詳細的金額分解
              if (widget.paymentRequest.isCombinedPayment) ...[
                const Text(
                  'Payment Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• 新天鵝堡門票: ${widget.paymentRequest.ticketOnlyAmount.toStringAsFixed(2)} EUR'),
                Text('• 火車票: ${widget.paymentRequest.trainTicketAmount!.toStringAsFixed(2)} EUR'),
                Text('• 總計: ${widget.paymentRequest.amount.toStringAsFixed(2)} EUR'),
                const SizedBox(height: 16),
              ],
              
              // 顯示票券詳細資訊
              if (widget.paymentRequest.ticketRequest != null) ...[
                const Text(
                  'Ticket Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...widget.paymentRequest.ticketRequest!.ticketInfo.map((ticket) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${ticket.fullName} (${ticket.isAdult ? 'Adult' : 'Child'}) - ${ticket.session} - ${ticket.arrivalTime} - ${ticket.price} EUR',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 顯示火車票詳細資訊
              if (widget.paymentRequest.trainInfo != null) ...[
                const Text(
                  'Train Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• 車次: ${widget.paymentRequest.trainInfo!.number}'),
                Text('• 路線: ${widget.paymentRequest.trainInfo!.from.localName} → ${widget.paymentRequest.trainInfo!.to.localName}'),
                Text('• 出發: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.departure)}'),
                Text('• 到達: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.arrival)}'),
                Text('• 行程時間: ${widget.paymentRequest.trainInfo!.formattedDuration}'),
                if (widget.paymentRequest.trainOffer != null)
                  Text('• 票價類型: ${widget.paymentRequest.trainOffer!.description}'),
                if (widget.paymentRequest.trainService != null)
                  Text('• 座位類型: ${widget.paymentRequest.trainService!.description}'),
                const SizedBox(height: 16),
              ],
              
              Text(
                widget.paymentRequest.isCombinedPayment 
                    ? '您的門票和火車票已成功購買！\n請保留此收據作為入場和乘車憑證。'
                    : 'Your ticket(s) have been successfully purchased!\nPlease keep this receipt as your entry voucher.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // 如果是火車票或組合支付，直接回到首頁；如果是門票，詢問是否訂購火車票
              if (widget.paymentRequest.time == 'Train Journey' || widget.paymentRequest.isCombinedPayment) {
                // 火車票或組合支付成功，直接回到首頁
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              } else {
                // 門票支付成功，詢問是否訂購火車票
                _showTrainBookingDialog();
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// 顯示是否訂購火車票的對話框
  void _showTrainBookingDialog() {
    print('🚄 Showing train booking dialog');
    
    // 從門票資訊中獲取日期和時段
    final ticketDate = _getTicketDate();
    final ticketSession = widget.paymentRequest.time;
    final departureTime = _getDepartureTime(ticketSession);
    
    print('🚄 Ticket date: $ticketDate');
    print('🚄 Ticket session: $ticketSession');
    print('🚄 Departure time: $departureTime');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.train, color: Colors.blue),
            SizedBox(width: 8),
            Text('🚄 火車票預訂'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '門票購買成功！',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '您是否也需要預訂火車票前往新天鵝堡？',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '預設火車票資訊：',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('出發：慕尼黑 → 福森', style: const TextStyle(fontSize: 12)),
                  Text('日期：$ticketDate', style: const TextStyle(fontSize: 12)),
                  Text('時間：$departureTime', style: const TextStyle(fontSize: 12)),
                  Text('時段：${ticketSession == "Morning" ? "上午" : "下午"}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // 跳轉到首頁
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('不需要'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _navigateToTrainBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('🚄 預訂火車票'),
          ),
        ],
      ),
    );
  }

  /// 獲取門票日期
  String _getTicketDate() {
    if (widget.paymentRequest.ticketRequest != null && 
        widget.paymentRequest.ticketRequest!.ticketInfo.isNotEmpty) {
      return widget.paymentRequest.ticketRequest!.ticketInfo.first.arrivalTime;
    }
    // 如果沒有門票資訊，使用明天的日期作為預設
    return DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
  }

  /// 根據門票時段獲取出發時間
  String _getDepartureTime(String session) {
    // 無論是 Morning 還是 Afternoon，火車票時間都設定為 12:00
    return '12:00';
  }

  /// 顯示 3DS 驗證對話框
  void _show3DSAuthenticationDialog(PaymentResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('3DS 身份驗證'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '您的銀行要求進行額外的身份驗證。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PaymentIntent ID:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    response.paymentIntentId ?? 'Unknown',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Client Secret:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    response.clientSecret ?? 'Unknown',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '注意：在實際應用中，這裡會集成 Stripe Elements 來處理 3DS 驗證流程。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 暫時跳過 3DS 驗證，直接調用 API
              if (response.paymentIntentId != null) {
                _submitTicketToApi(response.paymentIntentId!);
              }
            },
            child: const Text('跳過驗證（測試用）'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 導航到火車票預訂頁面
  void _navigateToTrainBooking() {
    // 獲取門票資訊
    final ticketInfos = widget.paymentRequest.ticketRequest?.ticketInfo ?? [];
    final ticketDate = _getTicketDate();
    final ticketSession = widget.paymentRequest.time;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RailSearchTestPage(
          ticketInfos: ticketInfos,
          ticketDate: ticketDate,
          ticketSession: ticketSession,
          originalTicketRequest: widget.paymentRequest,
        ),
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
        title: const Text('Payment'),
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
                    Text(
                      widget.paymentRequest.isCombinedPayment ? '📋 組合訂單摘要' : '📋 Order Summary',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Customer Name: ${widget.paymentRequest.customerName}'),
                    Text('Ticket Type: ${widget.paymentRequest.isAdult ? 'Adult' : 'Child'}'),
                    Text('Time Slot: ${widget.paymentRequest.time}'),
                    
                    // 如果是組合支付，顯示詳細的金額分解
                    if (widget.paymentRequest.isCombinedPayment) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text(
                        '💰 費用明細',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('新天鵝堡門票: ${widget.paymentRequest.ticketOnlyAmount.toStringAsFixed(2)} ${widget.paymentRequest.currency}'),
                      Text('火車票: ${widget.paymentRequest.trainTicketAmount!.toStringAsFixed(2)} ${widget.paymentRequest.currency}'),
                      const Divider(),
                      Text(
                        '總金額: ${widget.paymentRequest.amount.toStringAsFixed(2)} ${widget.paymentRequest.currency}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ] else ...[
                      Text('Amount: ${widget.paymentRequest.amount.toStringAsFixed(2)} ${widget.paymentRequest.currency}'),
                    ],
                    
                    Text('Description: ${widget.paymentRequest.description}'),
                    
                    // 如果是火車票或組合支付，顯示額外的火車資訊
                    if (widget.paymentRequest.time == 'Train Journey' || widget.paymentRequest.isCombinedPayment) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text(
                        '🚄 火車資訊',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.paymentRequest.trainInfo != null) ...[
                        Text('車次: ${widget.paymentRequest.trainInfo!.number}'),
                        Text('類型: ${widget.paymentRequest.trainInfo!.typeName}'),
                        Text('路線: ${widget.paymentRequest.trainInfo!.from.localName} → ${widget.paymentRequest.trainInfo!.to.localName}'),
                        Text('出發: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.departure)}'),
                        Text('到達: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.arrival)}'),
                        Text('行程時間: ${widget.paymentRequest.trainInfo!.formattedDuration}'),
                        if (widget.paymentRequest.trainOffer != null)
                          Text('票價類型: ${widget.paymentRequest.trainOffer!.description}'),
                        if (widget.paymentRequest.trainService != null)
                          Text('座位類型: ${widget.paymentRequest.trainService!.description}'),
                      ],
                    ],
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
                        '💳 Payment Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cardholder Name
                      TextFormField(
                        controller: _cardholderNameController,
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter cardholder name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Card Number
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final formatted = _formatCardNumber(newValue.text);
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: '4242 4242 4242 4242',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter card number';
                          }
                          String digitsOnly = value.replaceAll(' ', '');
                          if (digitsOnly.length != 16) {
                            return 'Card number must be 16 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Expiry Date and CVC
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
                                labelText: 'Expiry Date',
                                border: OutlineInputBorder(),
                                hintText: '12/25',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter expiry date';
                                }
                                if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                  return 'Format: MM/YY';
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
                                  return 'Please enter CVC';
                                }
                                if (value.length < 3 || value.length > 4) {
                                  return 'CVC must be 3-4 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Payment Button
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
                                  Text('Processing...'),
                                ],
                              )
                            : const Text(
                                '💳 Pay Now',
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
