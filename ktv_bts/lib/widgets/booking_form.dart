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
  
  // Form controllers
  final _emailController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _givenNameController = TextEditingController();
  
  // Form state
  bool _isAdult = true;
  DateTime? _selectedDate;
  String _selectedSession = 'Morning';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _familyNameController.dispose();
    _givenNameController.dispose();
    super.dispose();
  }

  /// 處理表單提交
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Please select an arrival date');
      return;
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
    _showSuccessSnackBar('Form submitted successfully! Payment integration coming in next phase.');
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
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Arrival Date',
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
          const SizedBox(height: 16),

          // Name Fields Row
          Row(
            children: [
              // Family Name
              Expanded(
                child: TextFormField(
                  controller: _familyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Family Name',
                    hintText: 'Enter your family name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
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
                  controller: _givenNameController,
                  decoration: const InputDecoration(
                    labelText: 'Given Name',
                    hintText: 'Enter your given name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
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
            ),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text('Adult (19 EUR)'),
                  subtitle: const Text('18 years and above'),
                  value: true,
                  groupValue: _isAdult,
                  onChanged: (value) {
                    setState(() {
                      _isAdult = value!;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('Under 18 (Free)'),
                  subtitle: const Text('Under 18 years old'),
                  value: false,
                  groupValue: _isAdult,
                  onChanged: (value) {
                    setState(() {
                      _isAdult = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date Selection
          const Text(
            'Arrival Date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Select arrival date'
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Session Selection
          const Text(
            'Time Session',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Morning'),
                  subtitle: const Text('9:00 AM - 12:00 PM'),
                  value: 'Morning',
                  groupValue: _selectedSession,
                  onChanged: (value) {
                    setState(() {
                      _selectedSession = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Afternoon'),
                  subtitle: const Text('1:00 PM - 5:00 PM'),
                  value: 'Afternoon',
                  groupValue: _selectedSession,
                  onChanged: (value) {
                    setState(() {
                      _selectedSession = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Price Display
          PriceDisplay(
            isAdult: _isAdult,
            quantity: 1,
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
                  : const Text(
                      'Book Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
