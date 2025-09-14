import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/main_page_provider.dart';
import '../models/search_option.dart';

/// 車站票券組件 - 火車票申請表單
class StationTicketWidget extends StatefulWidget {
  const StationTicketWidget({super.key});

  @override
  State<StationTicketWidget> createState() => _StationTicketWidgetState();
}

class _StationTicketWidgetState extends State<StationTicketWidget> {
  final _formKey = GlobalKey<FormState>();
  
  // 表單狀態
  String? _selectedDestination;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _adultCount = 1;
  int _childCount = 0;
  bool _isSearching = false;

  // 目的地選項（基於當前選中的車站）
  List<SearchOption> get _availableDestinations {
    final provider = context.read<MainPageProvider>();
    final currentStation = provider.selectedOption;
    
    if (currentStation == null) return [];
    
    // 排除當前選中的車站，返回其他車站選項
    return SearchOptions.stations
        .where((station) => station.id != currentStation.id)
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<MainPageProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                Row(
                  children: [
                    Icon(
                      Icons.train,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Train Ticket Booking',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // 火車票搜索表單
                _buildTrainSearchForm(provider),
                
                const SizedBox(height: 24),
                
                // 搜索按鈕
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSearching || _selectedDestination == null) 
                        ? null 
                        : () => _handleTrainSearch(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Search Trains',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 建立火車票搜索表單
  Widget _buildTrainSearchForm(MainPageProvider provider) {
    final currentStation = provider.selectedOption;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 出發站顯示
        _buildStationInfo('From', currentStation?.name ?? 'Unknown Station', Icons.departure_board),
        
        const SizedBox(height: 16),
        
        // 目的地選擇
        _buildDestinationDropdown(),
        
        const SizedBox(height: 16),
        
        // 日期和時間選擇
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker()),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 乘客數量選擇
        _buildPassengerCounters(),
      ],
    );
  }

  /// 建立車站資訊顯示
  Widget _buildStationInfo(String label, String stationName, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
          Expanded(
            child: Text(
              stationName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立目的地下拉選單
  Widget _buildDestinationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'To',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDestination,
          decoration: InputDecoration(
            hintText: 'Select destination',
            prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade600),
            ),
          ),
          items: _availableDestinations.map((station) {
            return DropdownMenuItem<String>(
              value: station.stationCode,
              child: Row(
                children: [
                  Text(station.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      station.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDestination = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a destination';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 建立日期選擇器
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 建立時間選擇器
  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 建立乘客數量計數器
  Widget _buildPassengerCounters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passengers',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPassengerCounter(
                'Adults',
                _adultCount,
                (value) => setState(() => _adultCount = value),
                minValue: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPassengerCounter(
                'Children',
                _childCount,
                (value) => setState(() => _childCount = value),
                minValue: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 建立單個乘客計數器
  Widget _buildPassengerCounter(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    int minValue = 0,
    int maxValue = 9,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: value > minValue
                    ? () => onChanged(value - 1)
                    : null,
                icon: const Icon(Icons.remove),
                iconSize: 18,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: value < maxValue
                    ? () => onChanged(value + 1)
                    : null,
                icon: const Icon(Icons.add),
                iconSize: 18,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 選擇日期
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 選擇時間
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// 處理火車搜索
  Future<void> _handleTrainSearch(MainPageProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final currentStation = provider.selectedOption;
    if (currentStation?.stationCode == null || _selectedDestination == null) {
      _showErrorMessage('Please select both departure and destination stations');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Web 平台模擬搜索
      await _handleMockTrainSearch(currentStation!, _selectedDestination!);
    } catch (e) {
      _showErrorMessage('Search failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  /// 處理模擬火車搜索
  Future<void> _handleMockTrainSearch(SearchOption from, String toStationCode) async {
    // 模擬搜索延遲
    await Future.delayed(const Duration(seconds: 1));
    
    final toStation = SearchOptions.stations.firstWhere(
      (station) => station.stationCode == toStationCode,
      orElse: () => SearchOptions.stations.first,
    );
    
    if (mounted) {
      _showSuccessMessage(
        'Train Search Results\n\n'
        '🚉 Route: ${from.name} → ${toStation.name}\n'
        '📅 Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}\n'
        '⏰ Time: ${_selectedTime.format(context)}\n'
        '👥 Passengers: $_adultCount adults, $_childCount children\n\n'
        '✅ Search completed successfully!\n'
        '(Demo mode - actual booking would show available trains)'
      );
    }
  }

  /// 顯示錯誤訊息
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  /// 顯示成功訊息
  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

}
