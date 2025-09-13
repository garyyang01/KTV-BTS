import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/email_input.dart';
import '../widgets/price_display.dart';

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
  
  // Loading state
  bool _isLoading = false;

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

    setState(() {
      _isLoading = true;
    });

    // 模擬 API 呼叫
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // TODO: 實際的支付整合將在階段四實作
    _showSuccessSnackBar('${_tickets.length} ticket(s) submitted successfully! Payment integration coming in next phase.');
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

  /// 顯示成功訊息
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...'),
                      ],
                    )
                  : Text(
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
