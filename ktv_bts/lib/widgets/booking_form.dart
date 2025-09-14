import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/email_input.dart';
import '../widgets/price_display.dart';
import '../models/ticket_request.dart';
import '../models/ticket_info.dart';
import '../models/payment_request.dart';
import '../models/search_option.dart';
import '../pages/payment_page.dart';
import '../pages/rail_search_test_page.dart';
import '../services/ip_verification_service.dart';

/// 預訂表單組件
/// 包含所有票券預訂所需的輸入欄位
class BookingForm extends StatefulWidget {
  final SearchOption? selectedAttraction;
  
  const BookingForm({
    super.key,
    this.selectedAttraction,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _ipVerificationService = IpVerificationService();

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

  /// 獲取景點票價
  Map<String, int> _getAttractionPrices() {
    if (widget.selectedAttraction?.metadata != null) {
      final ticketPrice = widget.selectedAttraction!.metadata!['ticketPrice'] as Map<String, dynamic>?;
      if (ticketPrice != null) {
        return {
          'adult': ticketPrice['adult'] as int? ?? 19,
          'child': ticketPrice['child'] as int? ?? 1,
        };
      }
    }
    // 預設為 Neuschwanstein Castle 的價格
    return {'adult': 19, 'child': 1};
  }

  /// 獲取成人票價
  int _getAdultPrice() => _getAttractionPrices()['adult']!;

  /// 獲取兒童票價
  int _getChildPrice() => _getAttractionPrices()['child']!;

  /// 添加新票券
  void _addNewTicket() {
    setState(() {
      final isFirstTicket = _tickets.isEmpty;
      _tickets.add({
        'familyNameController': TextEditingController(),
        'givenNameController': TextEditingController(),
        'isAdult': true,
        'selectedDate': isFirstTicket ? null : _tickets.first['selectedDate'],
        'selectedSession': isFirstTicket ? 'Morning' : _tickets.first['selectedSession'],
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
    print('=== 開始處理表單提交 ===');
    
    if (!_formKey.currentState!.validate()) {
      print('表單驗證失敗');
      print('Email: "${_emailController.text}"');
      for (int i = 0; i < _tickets.length; i++) {
        final ticket = _tickets[i];
        print('票券 ${i + 1}:');
        print('  Family Name: "${ticket['familyNameController'].text}"');
        print('  Given Name: "${ticket['givenNameController'].text}"');
        print('  Selected Date: ${ticket['selectedDate']}');
        print('  Selected Session: ${ticket['selectedSession']}');
      }
      return;
    }
    print('表單驗證通過');

    // 驗證所有票券都有選擇日期
    for (int i = 0; i < _tickets.length; i++) {
      print('檢查票券 ${i + 1} 的日期: ${_tickets[i]['selectedDate']}');
      if (_tickets[i]['selectedDate'] == null) {
        print('票券 ${i + 1} 沒有選擇日期');
        _showErrorSnackBar(AppLocalizations.of(context)!.pleaseSelectArrivalDate('${i + 1}'));
        return;
      }
    }
    print('所有票券日期驗證通過');

    // 在用戶選擇票種後，進行 IP 驗證檢查
    print('開始 IP 驗證...');
    final isIpAuthorized = await _ipVerificationService.verifyUserIp();
    print('IP 驗證結果: $isIpAuthorized');
    if (!isIpAuthorized) {
      print('IP 驗證失敗，顯示阻擋對話框');
      _showIpBlockedDialog();
      return;
    }
    print('IP 驗證通過');

    // 創建 TicketRequest 物件
    print('創建 TicketRequest...');
    try {
      final ticketRequest = _createTicketRequest();
      print('TicketRequest 創建成功');

      // 創建 PaymentRequest 物件
      print('創建 PaymentRequest...');
      final paymentRequest = _createPaymentRequest(ticketRequest);
      print('PaymentRequest 創建成功');

      // 顯示火車票預訂對話框
      print('顯示火車票預訂對話框...');
      _showTrainBookingDialog(paymentRequest);
      print('=== 表單提交處理完成 ===');
    } catch (e) {
      print('創建請求時發生錯誤: $e');
      _showErrorSnackBar(AppLocalizations.of(context)!.errorCreatingBookingRequest(e.toString()));
    }
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

  /// 顯示 IP 被阻擋的對話框
  void _showIpBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.accessDenied),
          ],
        ),
        content: Text(_ipVerificationService.getBlockedUserMessage()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.train, color: Colors.blue.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.trainTicketBooking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.ticketInformationConfirmed,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.doYouNeedTrainTickets(widget.selectedAttraction?.name ?? 'Neuschwanstein Castle'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.purple.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.defaultTrainTicketInformation,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, AppLocalizations.of(context)!.route, _getTrainRoute()),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, AppLocalizations.of(context)!.date, ticketDate),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time, AppLocalizations.of(context)!.time, departureTime),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.schedule, AppLocalizations.of(context)!.session, ticketSession == 'Morning' ? AppLocalizations.of(context)!.morning : AppLocalizations.of(context)!.afternoon),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // 直接進入支付頁面（只買門票）
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(paymentRequest: paymentRequest),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.ticketOnly,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    _navigateToTrainBooking(paymentRequest);
                  },
                  icon: const Icon(Icons.train, size: 18),
                  label: Text(AppLocalizations.of(context)!.bookTrainTickets),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build info row for train booking dialog
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: Colors.blue.shade600),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  /// 根據景點獲取火車路線
  String _getTrainRoute() {
    final attractionId = widget.selectedAttraction?.id;
    switch (attractionId) {
      case 'neuschwanstein':
        return 'Munich → Füssen';
      case 'uffizi':
        return 'Milano Centrale → Florence SMN';
      default:
        return 'Munich → Füssen'; // 預設為 Neuschwanstein Castle 的路線
    }
  }

  /// 導航到火車票預訂頁面
  void _navigateToTrainBooking(PaymentRequest paymentRequest) {
    // 獲取門票資訊
    final ticketInfos = paymentRequest.ticketRequest?.ticketInfo ?? [];
    final ticketDate = _getTicketDate(paymentRequest);
    final ticketSession = paymentRequest.time;
    
    // 獲取用戶信息
    final email = _emailController.text.trim();
    final firstName = ticketInfos.isNotEmpty ? ticketInfos.first.givenName : '';
    final lastName = ticketInfos.isNotEmpty ? ticketInfos.first.familyName : '';
    
    // 根據景點獲取車站資訊
    final attractionId = widget.selectedAttraction?.id;
    String departureStation;
    String destinationStation;
    
    switch (attractionId) {
      case 'neuschwanstein':
        departureStation = 'Munich Central Station';
        destinationStation = 'Füssen Station';
        break;
      case 'uffizi':
        departureStation = 'Milano Centrale';
        destinationStation = 'Florence SMN';
        break;
      default:
        departureStation = 'Munich Central Station';
        destinationStation = 'Füssen Station';
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RailSearchTestPage(
          ticketInfos: ticketInfos,
          ticketDate: ticketDate,
          ticketSession: ticketSession,
          originalTicketRequest: paymentRequest,
          passengerEmail: email,
          passengerFirstName: firstName,
          passengerLastName: lastName,
          departureStation: departureStation,
          destinationStation: destinationStation,
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
      helpText: AppLocalizations.of(context)!.selectArrivalDateForAllTickets,
    );
    
    if (picked != null && picked != _tickets[ticketIndex]['selectedDate']) {
      setState(() {
        // 更新所有票券的日期
        for (int i = 0; i < _tickets.length; i++) {
          _tickets[i]['selectedDate'] = picked;
        }
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
      final selectedDate = ticket['selectedDate'] as DateTime?;
      
      // 確保日期不為 null
      if (selectedDate == null) {
        print('錯誤：票券日期為 null');
        throw Exception('Ticket date cannot be null');
      }
      
      final arrivalTime = DateFormat('yyyy-MM-dd').format(selectedDate);
      final price = isAdult ? _getAdultPrice().toDouble() : _getChildPrice().toDouble();
      
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
    final attractionName = widget.selectedAttraction?.name ?? 'Neuschwanstein Castle';
    String description = '$attractionName Tickets - ';
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
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.ticketNumber('${index + 1}'),
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              if (_tickets.length > 1)
                IconButton(
                  onPressed: () => _removeTicket(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: AppLocalizations.of(context)!.removeTicket,
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.familyName,
                    hintText: AppLocalizations.of(context)!.familyNameHint,
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.familyNameRequired;
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.givenName,
                    hintText: AppLocalizations.of(context)!.givenNameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.givenNameRequired;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Age Group Selection
          Text(
            AppLocalizations.of(context)!.ageGroup,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
            ),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: Text(
                    '${AppLocalizations.of(context)!.adult} (${_getAdultPrice()} EUR)',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.adultDescription,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  value: true,
                  groupValue: ticket['isAdult'],
                  onChanged: (value) {
                    setState(() {
                      ticket['isAdult'] = value!;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: Text(
                    '${AppLocalizations.of(context)!.under18} (${_getChildPrice() == 0 ? AppLocalizations.of(context)!.free : '${_getChildPrice()} EUR'})',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.under18Description,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
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

          // Date and Session Row (only show for first ticket)
          if (index == 0) ...[
            Row(
              children: [
                // Date Selection
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.arrivalDate,
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(index),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today, 
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ticket['selectedDate'] == null
                                      ? AppLocalizations.of(context)!.selectDate
                                      : DateFormat('yyyy-MM-dd').format(ticket['selectedDate']),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: ticket['selectedDate'] == null 
                                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey)
                                        : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
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
                      Text(
                        AppLocalizations.of(context)!.session,
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: ticket['selectedSession'],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Morning', 
                            child: Text(
                              AppLocalizations.of(context)!.morning,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Afternoon', 
                            child: Text(
                              AppLocalizations.of(context)!.afternoon,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            ticket['selectedSession'] = value;
                            // 更新所有其他票券的時段
                            for (int i = 1; i < _tickets.length; i++) {
                              _tickets[i]['selectedSession'] = value;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Show date and session info for additional tickets
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blue.shade900.withOpacity(0.3) 
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.blue.shade600 
                      : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.dateSessionInfo(
                        ticket['selectedDate'] != null ? DateFormat('yyyy-MM-dd').format(ticket['selectedDate']) : AppLocalizations.of(context)!.notSelected,
                        ticket['selectedSession']
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.blue.shade400 
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          Text(
            AppLocalizations.of(context)!.ticketInformation,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Tickets List
          ...List.generate(_tickets.length, (index) => _buildTicketCard(index)),

          // Add Another Ticket Button
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addNewTicket,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.addAnotherTicket),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),

          // Price Display
          PriceDisplay(
            tickets: _tickets,
            adultPrice: _getAdultPrice(),
            childPrice: _getChildPrice(),
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
                AppLocalizations.of(context)!.bookTicketsNow('${_tickets.length}', _tickets.length > 1 ? 's' : ''),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
