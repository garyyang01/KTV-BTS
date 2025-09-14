import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/email_input.dart';
import '../widgets/price_display.dart';
import '../models/ticket_request.dart';
import '../models/ticket_info.dart';
import '../models/payment_request.dart';
import '../pages/payment_page.dart';
import '../pages/rail_search_test_page.dart';

/// 預訂表單組件
/// 包含所有票券預訂所需的輸入欄位
class BookingForm extends StatefulWidget {
  const BookingForm({super.key});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Email controller
  final _emailController = TextEditingController();
  
  // Tickets list - each ticket contains its own form data
  List<Map<String, dynamic>> _tickets = [];
  
  // Loading state (no longer needed since we show dialog immediately)
  // bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with one ticket
    _addNewTicket();
  }

  @override
  void dispose() {
    _emailController.dispose();
    // Dispose all ticket controllers
    for (var ticket in _tickets) {
      ticket['familyNameController']?.dispose();
      ticket['givenNameController']?.dispose();
    }
    super.dispose();
  }

  /// 添加新票券
  void _addNewTicket() {
    setState(() {
      _tickets.add({
        'familyNameController': TextEditingController(),
        'givenNameController': TextEditingController(),
        'isAdult': true,
        'selectedDate': null,
        'selectedSession': 'Morning',
      });
    });
  }

  /// 移除票券
  void _removeTicket(int index) {
    if (_tickets.length > 1) {
      setState(() {
        // Dispose controllers before removing
        _tickets[index]['familyNameController']?.dispose();
        _tickets[index]['givenNameController']?.dispose();
        _tickets.removeAt(index);
      });
    }
  }

  /// 處理表單提交
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 驗證所有票券都有選擇日期
    for (int i = 0; i < _tickets.length; i++) {
      if (_tickets[i]['selectedDate'] == null) {
        _showErrorSnackBar('Please select an arrival date for ticket ${i + 1}');
        return;
      }
    }

    // 創建 TicketRequest 物件
    final ticketRequest = _createTicketRequest();
    
    // 創建 PaymentRequest 物件
    final paymentRequest = _createPaymentRequest(ticketRequest);

    // 顯示火車票預訂對話框
    _showTrainBookingDialog(paymentRequest);
  }

  /// 顯示錯誤訊息
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 顯示是否訂購火車票的對話框
  void _showTrainBookingDialog(PaymentRequest paymentRequest) {
    // 從門票資訊中獲取日期和時段
    final ticketDate = _getTicketDate(paymentRequest);
    final ticketSession = paymentRequest.time;
    final departureTime = _getDepartureTime(ticketSession);
    
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
              '門票資訊確認完成！',
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
              // 直接進入支付頁面（只買門票）
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PaymentPage(paymentRequest: paymentRequest),
                ),
              );
            },
            child: const Text('只要門票'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _navigateToTrainBooking(paymentRequest);
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
  String _getTicketDate(PaymentRequest paymentRequest) {
    if (paymentRequest.ticketRequest != null && 
        paymentRequest.ticketRequest!.ticketInfo.isNotEmpty) {
      return paymentRequest.ticketRequest!.ticketInfo.first.arrivalTime;
    }
    return DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
  }

  /// 根據門票時段獲取出發時間
  String _getDepartureTime(String session) {
    // 無論是 Morning 還是 Afternoon，火車票時間都設定為 12:00
    return '12:00';
  }

  /// 導航到火車票預訂頁面
  void _navigateToTrainBooking(PaymentRequest paymentRequest) {
    // 獲取門票資訊
    final ticketInfos = paymentRequest.ticketRequest?.ticketInfo ?? [];
    final ticketDate = _getTicketDate(paymentRequest);
    final ticketSession = paymentRequest.time;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RailSearchTestPage(
          ticketInfos: ticketInfos,
          ticketDate: ticketDate,
          ticketSession: ticketSession,
          originalTicketRequest: paymentRequest,
        ),
      ),
    );
  }


  /// 選擇日期
  Future<void> _selectDate(int ticketIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Arrival Date for Ticket ${ticketIndex + 1}',
    );
    
    if (picked != null && picked != _tickets[ticketIndex]['selectedDate']) {
      setState(() {
        _tickets[ticketIndex]['selectedDate'] = picked;
      });
    }
  }

  /// 創建 TicketRequest 物件
  TicketRequest _createTicketRequest() {
    final ticketInfoList = <TicketInfo>[];
    
    for (var ticket in _tickets) {
      final familyName = ticket['familyNameController'].text.trim();
      final givenName = ticket['givenNameController'].text.trim();
      final isAdult = ticket['isAdult'] as bool;
      final session = ticket['selectedSession'] as String;
      final selectedDate = ticket['selectedDate'] as DateTime;
      final arrivalTime = DateFormat('yyyy-MM-dd').format(selectedDate);
      final price = isAdult ? 19.0 : 1.0; // 成人19歐元，兒童1歐元
      
      ticketInfoList.add(TicketInfo(
        familyName: familyName,
        givenName: givenName,
        isAdult: isAdult,
        session: session,
        arrivalTime: arrivalTime,
        price: price,
      ));
    }
    
    return TicketRequest(
      recipientEmail: _emailController.text.trim(),
      totalTickets: _tickets.length,
      ticketInfo: ticketInfoList,
    );
  }

  /// 創建 PaymentRequest 物件
  PaymentRequest _createPaymentRequest(TicketRequest ticketRequest) {
    // 計算總金額
    final totalAmount = ticketRequest.totalAmount;
    
    // 創建客戶名稱（使用第一個票券的姓名）
    final firstTicket = ticketRequest.ticketInfo.first;
    final customerName = '${firstTicket.familyName} ${firstTicket.givenName}';
    
    // 創建描述
    final adultCount = ticketRequest.adultTickets.length;
    final childCount = ticketRequest.childTickets.length;
    String description = 'Neuschwanstein Castle Tickets - ';
    if (adultCount > 0) description += '$adultCount Adult';
    if (adultCount > 0 && childCount > 0) description += ', ';
    if (childCount > 0) description += '$childCount Child';
    
    return PaymentRequest(
      customerName: customerName,
      isAdult: adultCount > 0, // 如果有成人票就設為成人
      time: firstTicket.session, // 使用第一個票券的時段
      amount: totalAmount,
      currency: 'EUR',
      description: description,
      ticketRequest: ticketRequest,
    );
  }

  /// 建立票券卡片
  Widget _buildTicketCard(int index) {
    final ticket = _tickets[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket ${index + 1}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_tickets.length > 1)
                IconButton(
                  onPressed: () => _removeTicket(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove ticket',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Name Fields Row
          Row(
            children: [
              // Family Name
              Expanded(
                child: TextFormField(
                  controller: ticket['familyNameController'],
                  decoration: const InputDecoration(
                    labelText: 'Family Name',
                    hintText: 'Enter family name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Family name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Given Name
              Expanded(
                child: TextFormField(
                  controller: ticket['givenNameController'],
                  decoration: const InputDecoration(
                    labelText: 'Given Name',
                    hintText: 'Enter given name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Given name is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Age Group Selection
          const Text(
            'Age Group',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text('Adult (19 EUR)'),
                  subtitle: const Text('18 years and above'),
                  value: true,
                  groupValue: ticket['isAdult'],
                  onChanged: (value) {
                    setState(() {
                      ticket['isAdult'] = value!;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('Under 18 (1 EUR)'),
                  subtitle: const Text('Under 18 years old'),
                  value: false,
                  groupValue: ticket['isAdult'],
                  onChanged: (value) {
                    setState(() {
                      ticket['isAdult'] = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date and Session Row
          Row(
            children: [
              // Date Selection
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arrival Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(index),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ticket['selectedDate'] == null
                                    ? 'Select date'
                                    : DateFormat('yyyy-MM-dd').format(ticket['selectedDate']),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ticket['selectedDate'] == null ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Session Selection
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: ticket['selectedSession'],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            ticket['selectedSession'] = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Input
          EmailInput(
            controller: _emailController,
          ),
          const SizedBox(height: 24),

          // Tickets Section
          const Text(
            'Ticket Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Tickets List
          ...List.generate(_tickets.length, (index) => _buildTicketCard(index)),

          // Add Another Ticket Button
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addNewTicket,
            icon: const Icon(Icons.add),
            label: const Text('Add Another Ticket'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),

          // Price Display
          PriceDisplay(
            tickets: _tickets,
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Book ${_tickets.length} Ticket${_tickets.length > 1 ? 's' : ''} Now',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
