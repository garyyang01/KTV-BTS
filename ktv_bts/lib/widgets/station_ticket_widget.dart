import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/search_option.dart';
import '../pages/rail_search_test_page.dart';

/// 車站票券組件 - 火車票申請表單
class StationTicketWidget extends StatefulWidget {
  final SearchOption? selectedStation;

  const StationTicketWidget({
    super.key,
    this.selectedStation,
  });

  @override
  State<StationTicketWidget> createState() => _StationTicketWidgetState();
}

class _StationTicketWidgetState extends State<StationTicketWidget> {
  final _formKey = GlobalKey<FormState>();
  
  // 表單控制器
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _departureDateController = TextEditingController();
  final _departureTimeController = TextEditingController();
  
  // 表單狀態
  int _adultCount = 1;
  int _childCount = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _departureDateController.dispose();
    _departureTimeController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // 如果有選中的車站，設為出發地
    if (widget.selectedStation != null) {
      _departureController.text = widget.selectedStation!.name;
    }
    
    // 設置默認日期為明天
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _departureDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    
    // 設置默認時間為上午9點
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    // 不在 initState 中使用 context，延遲到 build 方法中設置
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在這裡安全地使用 context
    if (_selectedTime != null && _departureTimeController.text.isEmpty) {
      _departureTimeController.text = _selectedTime!.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            _buildHeader(),
            
            const SizedBox(height: 20),
            
            // 路線選擇
            _buildRouteSection(),
            
            const SizedBox(height: 20),
            
            // 日期時間選擇
            _buildDateTimeSection(),
            
            const SizedBox(height: 20),
            
            // 乘客數量
            _buildPassengerSection(),
            
            const SizedBox(height: 24),
            
            // 搜索按鈕
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  /// 建立標題區域
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.train,
          color: Colors.blue.shade600,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Train Ticket Booking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (widget.selectedStation != null)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'From: ${widget.selectedStation!.name}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  /// 建立路線選擇區域
  Widget _buildRouteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Selection',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            // 出發地
            Expanded(
              child: TextFormField(
                controller: _departureController,
                decoration: InputDecoration(
                  labelText: 'Departure',
                  hintText: 'Select departure station',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select departure station';
                  }
                  return null;
                },
                readOnly: true,
                onTap: () => _showStationPicker(true),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 交換按鈕
            IconButton(
              onPressed: _swapStations,
              icon: Icon(
                Icons.swap_horiz,
                color: Colors.blue.shade600,
              ),
              tooltip: 'Swap stations',
            ),
            
            const SizedBox(width: 12),
            
            // 目的地
            Expanded(
              child: TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Select destination station',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select destination station';
                  }
                  return null;
                },
                readOnly: true,
                onTap: () => _showStationPicker(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 建立日期時間選擇區域
  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Departure Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            // 日期選擇
            Expanded(
              child: TextFormField(
                controller: _departureDateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 時間選擇
            Expanded(
              child: TextFormField(
                controller: _departureTimeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  hintText: 'Select time',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                readOnly: true,
                onTap: _selectTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 建立乘客數量選擇區域
  Widget _buildPassengerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passengers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // 成人數量
              _buildPassengerCounter(
                'Adults',
                'Age 18+',
                _adultCount,
                (value) => setState(() => _adultCount = value),
                minValue: 1,
              ),
              
              const SizedBox(height: 16),
              
              // 兒童數量
              _buildPassengerCounter(
                'Children',
                'Age 0-17',
                _childCount,
                (value) => setState(() => _childCount = value),
                minValue: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 建立乘客計數器
  Widget _buildPassengerCounter(
    String title,
    String subtitle,
    int count,
    ValueChanged<int> onChanged, {
    int minValue = 0,
    int maxValue = 9,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: count > minValue ? () => onChanged(count - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.blue.shade600,
            ),
            
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            IconButton(
              onPressed: count < maxValue ? () => onChanged(count + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.blue.shade600,
            ),
          ],
        ),
      ],
    );
  }

  /// 建立搜索按鈕
  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSearch,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
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
    );
  }

  /// 選擇日期
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _departureDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  /// 選擇時間
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _departureTimeController.text = picked.format(context);
      });
    }
  }

  /// 車站配對關係
  Map<String, String> get _stationPairs => {
    'Munich Central': 'Füssen Station',
    'Füssen Station': 'Munich Central',
    'Milano Centrale': 'Florence SMN',
    'Florence SMN': 'Milano Centrale',
  };

  /// 車站代碼映射
  Map<String, String> get _stationCodes => {
    'Munich Central': 'ST_EMYR64OX',
    'Füssen Station': 'ST_E7G93QNJ',
    'Milano Centrale': 'ST_L2330P6O',
    'Florence SMN': 'ST_DKRRM9Q4',
  };

  /// 獲取可選擇的車站列表
  List<SearchOption> _getAvailableStations(bool isDeparture) {
    final allStations = SearchOptions.stations;
    
    if (isDeparture) {
      // 出發地：顯示所有配對車站
      return allStations.where((station) => _stationPairs.containsKey(station.name)).toList();
    } else {
      // 目的地：根據已選擇的出發地來過濾
      final selectedDeparture = _departureController.text.trim();
      if (selectedDeparture.isEmpty) {
        return []; // 如果沒有選擇出發地，不顯示任何目的地
      }
      
      final pairedDestination = _stationPairs[selectedDeparture];
      if (pairedDestination == null) {
        return []; // 如果出發地沒有配對，不顯示任何目的地
      }
      
      return allStations.where((station) => station.name == pairedDestination).toList();
    }
  }

  /// 顯示車站選擇器
  void _showStationPicker(bool isDeparture) {
    final availableStations = _getAvailableStations(isDeparture);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDeparture ? 'Select Departure Station' : 'Select Destination Station',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (availableStations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isDeparture 
                    ? 'Please select a departure station first'
                    : 'No available destinations for the selected departure station',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...availableStations.map((station) => ListTile(
                leading: Text(station.icon, style: const TextStyle(fontSize: 24)),
                title: Text(station.name),
                subtitle: Text(station.description),
                onTap: () {
                  setState(() {
                    if (isDeparture) {
                      _departureController.text = station.name;
                      // 清空目的地選擇，讓用戶重新選擇配對的目的地
                      _destinationController.clear();
                    } else {
                      _destinationController.text = station.name;
                    }
                  });
                  Navigator.pop(context);
                },
              )),
          ],
        ),
      ),
    );
  }

  /// 交換出發地和目的地
  void _swapStations() {
    final departureText = _departureController.text.trim();
    final destinationText = _destinationController.text.trim();
    
    // 檢查是否為有效的配對
    if (_stationPairs.containsKey(departureText) && 
        _stationPairs[departureText] == destinationText) {
      setState(() {
        _departureController.text = destinationText;
        _destinationController.text = departureText;
      });
    } else {
      // 如果不是有效配對，顯示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only paired stations can be swapped'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    }
  }

  /// 處理搜索
  Future<void> _handleSearch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 獲取選擇的車站信息
      final departureStation = _departureController.text.trim();
      final destinationStation = _destinationController.text.trim();
      final departureDate = _departureDateController.text.trim();
      final departureTime = _departureTimeController.text.trim();
      
      // 跳轉到火車票搜尋頁面，傳遞選擇的信息
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RailSearchTestPage(
            departureStation: departureStation,
            destinationStation: destinationStation,
            departureDate: departureDate,
            departureTime: departureTime,
            adultCount: _adultCount,
            childCount: _childCount,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
