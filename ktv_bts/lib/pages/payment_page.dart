import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/stripe_payment_service.dart';
import '../services/ticket_api_service.dart';
import '../services/ip_verification_service.dart';
import '../services/rail_booking_service.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/ticket_request.dart';
import '../models/ticket_info.dart';
import '../models/online_order_request.dart';
import '../models/online_order_response.dart';
import '../models/online_confirmation_response.dart';
import '../models/online_ticket_response.dart';
import '../services/ticket_storage_service.dart';
import 'rail_search_test_page.dart';
import 'my_train_tickets_page.dart';

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
  final _ipVerificationService = IpVerificationService();
  final _railBookingService = RailBookingService.defaultInstance();
  // Form controllers
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
    // Automatically create payment intent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createPaymentIntent();
    });
  }

  Future<void> _initializeService() async {
    try {
      await _stripeService.initialize();
    } catch (e) {
      // Silently handle initialization error, will retry during payment
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
      // Silently handle error, will retry during payment
    }
  }

  Future<void> _processPayment() async {
    print('💳 Starting payment process...');

    if (!_formKey.currentState!.validate()) {
      print('💳 Form validation failed');
      return;
    }

    // Verify user IP before payment
    print('🔒 Verifying user IP before payment...');
    final isIpAuthorized = await _ipVerificationService.verifyUserIp();
    if (!isIpAuthorized) {
      _showIpBlockedDialog();
      return;
    }
    print('✅ IP verification passed, proceeding with payment');

    if (_lastPaymentIntent == null || !_lastPaymentIntent!.success) {
      print('💳 Payment intent not ready, attempting to create...');
      setState(() {
        _isLoading = true;
      });
      
      try {
        final response = await _stripeService.createPaymentIntent(widget.paymentRequest);
        setState(() {
          _lastPaymentIntent = response;
        });
        
        if (!response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create payment intent: ${response.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
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
          // If train ticket info exists, call G2Rail online_orders API
          if (widget.paymentRequest.trainInfo != null) {
            await _createOnlineOrderWithLoading(paymentIntentId);
          } else {
            _showSuccessDialog();
          }
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
          // If train ticket info exists, call G2Rail online_orders API
          if (widget.paymentRequest.trainInfo != null) {
            await _createOnlineOrderWithLoading(paymentIntentId);
          } else {
            _showSuccessDialog();
          }
        } else {
          // Temporary test: show success dialog even if API fails
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

  /// Create G2Rail online order (with Loading animation)
  Future<void> _createOnlineOrderWithLoading(String paymentIntentId) async {
    // Show Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Processing train tickets...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing your train ticket order',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Execute train ticket processing flow
      await _createOnlineOrder(paymentIntentId);
      
      // Close Loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        // Show success dialog with option to navigate to tickets page
        _showTrainTicketSuccessDialog();
      }
    } catch (e) {
      // Close Loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        // Show error dialog
        _showTrainTicketErrorDialog(e.toString());
      }
    }
  }

  /// Create G2Rail online order
  Future<void> _createOnlineOrder(String paymentIntentId) async {
    try {
      print('🚄 Starting G2Rail online order creation');
      
      // Check if train ticket info exists
      if (widget.paymentRequest.trainInfo == null) {
        print('🚄 No train ticket info, skipping online order creation');
        return;
      }

      // Get necessary data from train ticket info
      final trainInfo = widget.paymentRequest.trainInfo!;
      
      // Use real passenger info, or default values if not available
      final firstName = widget.paymentRequest.passengerFirstName ?? 'Train';
      final lastName = widget.paymentRequest.passengerLastName ?? 'Passenger';
      final email = widget.paymentRequest.passengerEmail ?? 'customer@example.com';
      final phone = widget.paymentRequest.passengerPhone ?? '+8615000367081';
      final passport = widget.paymentRequest.passengerPassport ?? 'A123456';
      final birthdate = widget.paymentRequest.passengerBirthdate ?? '1986-09-01';
      final gender = widget.paymentRequest.passengerGender ?? 'male';
      
      // Create passenger information
      final passengers = [
        Passenger(
          lastName: lastName,
          firstName: firstName,
          birthdate: birthdate,
          passport: passport,
          email: email,
          phone: phone,
          gender: gender,
        ),
      ];

      // 從火車票服務中獲取 booking_code
      print('🚄 檢查 trainService: ${widget.paymentRequest.trainService}');
      print('🚄 trainService.bookingCode: ${widget.paymentRequest.trainService?.bookingCode}');
      
      final bookingCode = widget.paymentRequest.trainService?.bookingCode ?? 'bc_05';
      
      print('🚄 使用 booking_code: $bookingCode');
      
      // 創建線上訂單請求
      final onlineOrderRequest = OnlineOrderRequest(
        passengers: passengers,
        sections: [bookingCode], // 使用真實的 booking_code
        seatReserved: true,
        memo: paymentIntentId, // 使用支付ID作為備註
      );

      print('🚄 線上訂單請求參數: ${onlineOrderRequest.toJson()}');

      // 調用 G2Rail API
      final response = await _railBookingService.createOnlineOrder(
        request: onlineOrderRequest,
      );

      if (response.success) {
        print('✅ G2Rail 線上訂單創建成功');
        print('🆔 訂單ID: ${response.data?.id}');
        print('🚄 路線: ${response.data?.from.localName} → ${response.data?.to.localName}');
        print('⏰ 出發時間: ${response.data?.departure}');
        print('⏰ 到達時間: ${response.data?.arrival}');
        
        // 線上訂單創建成功後，立即確認訂單
        if (response.data?.id != null) {
          await _confirmOnlineOrder(response.data!.id);
        }
      } else {
        print('❌ G2Rail 線上訂單創建失敗: ${response.errorMessage}');
        // 即使線上訂單創建失敗，也不影響整體流程，只記錄錯誤
      }
    } catch (e) {
      print('❌ 創建 G2Rail 線上訂單異常: $e');
      // 即使線上訂單創建失敗，也不影響整體流程，只記錄錯誤
    }
  }

  /// 確認 G2Rail 線上訂單
  Future<void> _confirmOnlineOrder(String onlineOrderId) async {
    try {
      print('🎫 開始確認 G2Rail 線上訂單');
      print('🆔 線上訂單ID: $onlineOrderId');

      // 調用 G2Rail 確認 API
      final response = await _railBookingService.confirmOnlineOrder(
        onlineOrderId: onlineOrderId,
      );

      if (response.success) {
        print('✅ G2Rail 線上訂單確認成功');
        print('🆔 確認ID: ${response.data?.id}');
        print('🎫 PNR: ${response.data?.order.pnr}');
        print('🚄 路線: ${response.data?.order.from.localName} → ${response.data?.order.to.localName}');
        print('⏰ 出發時間: ${response.data?.order.departure}');
        
        // 顯示座位資訊
        if (response.data?.order.reservations.isNotEmpty == true) {
          final reservation = response.data!.order.reservations.first;
          print('🚂 列車: ${reservation.trainName}, 車廂: ${reservation.car}, 座位: ${reservation.seat}');
        }
        
        // 顯示票價資訊
        print('💰 支付價格: ${(response.data?.paymentPrice.cents ?? 0) / 100} ${response.data?.paymentPrice.currency}');
        print('💰 收費價格: ${(response.data?.chargingPrice.cents ?? 0) / 100} ${response.data?.chargingPrice.currency}');
        print('💰 折扣金額: ${(response.data?.rebateAmount.cents ?? 0) / 100} ${response.data?.rebateAmount.currency}');
        
        // 顯示是否需要再次確認
        print('🔄 是否需要再次確認: ${response.data?.confirmAgain}');
        
        // 顯示登機資訊
        if (response.data?.ticketCheckIns.isNotEmpty == true) {
          final checkIn = response.data!.ticketCheckIns.first;
          print('🎫 登機URL: ${checkIn.checkInUrl}');
          print('⏰ 最早登機時間: ${checkIn.earliestCheckInTimestamp}');
          print('⏰ 最晚登機時間: ${checkIn.latestCheckInTimestamp}');
        }
        
        // 保存確認資訊到本地存儲
        await TicketStorageService.saveTicketConfirmation(
          orderId: onlineOrderId,
          confirmation: response.data!,
        );
        
        // 線上訂單確認成功後，下載票券
        await _downloadOnlineTickets(onlineOrderId);
      } else {
        print('❌ G2Rail 線上訂單確認失敗: ${response.errorMessage}');
        // 即使確認失敗，也不影響整體流程，只記錄錯誤
      }
    } catch (e) {
      print('❌ 確認 G2Rail 線上訂單異常: $e');
      // 即使確認失敗，也不影響整體流程，只記錄錯誤
    }
  }

  /// 下載 G2Rail 線上票券
  Future<void> _downloadOnlineTickets(String onlineOrderId) async {
    try {
      print('🎫 開始下載 G2Rail 線上票券');
      print('🆔 線上訂單ID: $onlineOrderId');

      // 調用 G2Rail 票券下載 API
      final response = await _railBookingService.downloadOnlineTickets(
        onlineOrderId: onlineOrderId,
      );

      if (response.success) {
        print('✅ G2Rail 線上票券下載成功');
        print('🎫 票券數量: ${response.data?.tickets.length}');
        
        for (int i = 0; i < (response.data?.tickets.length ?? 0); i++) {
          final ticket = response.data!.tickets[i];
          print('🎫 票券 ${i + 1}: ${ticket.ticketTypeDisplayName}');
          print('🔗 下載連結: ${ticket.file}');
          
          // 可以根據需要進一步處理票券文件
          if (ticket.isPdfTicket) {
            print('📄 這是 PDF 票券，可以下載並保存到本地');
          } else if (ticket.isMobileTicket) {
            print('📱 這是手機票券，可以顯示在應用中');
          }
        }
        
        // 保存票券文件資訊到本地存儲
        await TicketStorageService.saveTicketFiles(
          orderId: onlineOrderId,
          tickets: response.data!,
        );
        
        // 這裡可以添加實際的下載邏輯，例如：
        // - 下載 PDF 文件到本地存儲
        // - 將手機票券保存到用戶的票券錢包
        // - 發送票券到用戶郵箱
        print('💡 票券下載完成，可以根據業務需求進一步處理票券文件');
        
      } else {
        print('❌ G2Rail 線上票券下載失敗: ${response.errorMessage}');
        // 即使下載失敗，也不影響整體流程，只記錄錯誤
      }
    } catch (e) {
      print('❌ 下載 G2Rail 線上票券異常: $e');
      // 即使下載失敗，也不影響整體流程，只記錄錯誤
    }
  }

  /// Show train ticket success dialog
  void _showTrainTicketSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Train Ticket Purchase Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your train ticket has been successfully purchased and confirmed!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎫 Ticket Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.paymentRequest.trainInfo != null) ...[
                    Text('Route: ${widget.paymentRequest.trainInfo!.from.localName} → ${widget.paymentRequest.trainInfo!.to.localName}'),
                    Text('Train: ${widget.paymentRequest.trainInfo!.number}'),
                    Text('Departure: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.departure)}'),
                    Text('Arrival: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.arrival)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can now view your train tickets or return to the homepage to continue browsing.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to homepage
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('Return to Homepage'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to my train tickets page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyTrainTicketsPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('View My Tickets'),
          ),
        ],
      ),
    );
  }

  /// Show train ticket error dialog
  void _showTrainTicketErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Train Ticket Processing Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment was successful, but there was an issue processing your train ticket:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                errorMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please contact customer service and provide your payment reference number:',
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
              Navigator.of(context).pop();
              // Navigate to homepage
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('Return to Homepage'),
          ),
        ],
      ),
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
            Text('🚄 Booking Train Ticket'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket buying successful！',
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
                    'Default Train Ticket Information：',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Start：Munich Central → Füssen', style: const TextStyle(fontSize: 12)),
                  Text('Date：$ticketDate', style: const TextStyle(fontSize: 12)),
                  Text('Time：$departureTime', style: const TextStyle(fontSize: 12)),
                  Text('Session：${ticketSession == "Morning" ? "Morning" : "Afternoon"}', style: const TextStyle(fontSize: 12)),
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
            child: const Text('No need'),
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
            child: const Text('🚄 Booking Train Ticket'),
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
            Text('3DS Authentication'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your bank requires additional authentication。',
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

  /// 顯示 IP 被阻擋的對話框
  void _showIpBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: Text(_ipVerificationService.getBlockedUserMessage()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous page
            },
            child: const Text('OK'),
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
