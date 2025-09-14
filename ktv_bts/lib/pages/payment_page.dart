import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/stripe_payment_service.dart';
import '../services/ticket_api_service.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/ticket_request.dart';
import '../models/ticket_info.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lastPaymentIntent == null || !_lastPaymentIntent!.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create payment intent first'),
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
        // 支付成功，調用外部 API
        await _submitTicketToApi(response.paymentIntentId!);
      } else {
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
      // Check if we have ticket request data
      if (widget.paymentRequest.ticketRequest == null) {
        // Fallback to legacy single ticket format
        final legacyTicketRequest = _createLegacyTicketRequest();
        final apiResponse = await _ticketApiService.submitTicketRequest(
          paymentRefno: paymentIntentId,
          ticketRequest: legacyTicketRequest,
        );
        
        if (apiResponse.success) {
          _showSuccessDialog();
        } else {
          _showApiErrorDialog(apiResponse.errorMessage ?? 'Unknown error');
        }
      } else {
        // Use new ticket request format
        final apiResponse = await _ticketApiService.submitTicketRequest(
          paymentRefno: paymentIntentId,
          ticketRequest: widget.paymentRequest.ticketRequest!,
        );
        
        if (apiResponse.success) {
          _showSuccessDialog();
        } else {
          _showApiErrorDialog(apiResponse.errorMessage ?? 'Unknown error');
        }
      }
    } catch (e) {
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
              
              const Text(
                'Your ticket(s) have been successfully purchased!\nPlease keep this receipt as your entry voucher.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
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
            child: const Text('Done'),
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
                    const Text(
                      '📋 Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Customer Name: ${widget.paymentRequest.customerName}'),
                    Text('Ticket Type: ${widget.paymentRequest.isAdult ? 'Adult' : 'Child'}'),
                    Text('Time Slot: ${widget.paymentRequest.time}'),
                    Text('Amount: ${widget.paymentRequest.amount.toStringAsFixed(2)} ${widget.paymentRequest.currency}'),
                    Text('Description: ${widget.paymentRequest.description}'),
                    
                    // 如果是火車票，顯示額外的火車資訊
                    if (widget.paymentRequest.time == 'Train Journey') ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text(
                        '🚄 Train Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Journey: ${widget.paymentRequest.description}'),
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
