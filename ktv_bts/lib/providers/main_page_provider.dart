import 'package:flutter/material.dart';
import '../models/search_option.dart';

/// 主頁面狀態管理 Provider
class MainPageProvider extends ChangeNotifier {
  // 當前選中的搜索選項
  SearchOption? _selectedOption;
  
  // 載入狀態
  bool _isLoading = false;
  
  // 錯誤訊息
  String? _errorMessage;
  
  // 表單資料
  Map<String, dynamic> _formData = {};
  
  // 搜索歷史
  List<SearchOption> _searchHistory = [];
  
  // 最大搜索歷史記錄數
  static const int _maxHistoryCount = 10;

  // Getters
  SearchOption? get selectedOption => _selectedOption;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get formData => Map.unmodifiable(_formData);
  List<SearchOption> get searchHistory => List.unmodifiable(_searchHistory);
  
  // 是否有選中的選項
  bool get hasSelection => _selectedOption != null;
  
  // 當前選項類型
  SearchOptionType? get currentType => _selectedOption?.type;
  
  // 是否為車站類型
  bool get isStationType => currentType == SearchOptionType.station;
  
  // 是否為景點類型
  bool get isAttractionType => currentType == SearchOptionType.attraction;

  /// 選擇搜索選項
  void selectOption(SearchOption option) {
    if (_selectedOption?.id != option.id) {
      _selectedOption = option;
      _addToHistory(option);
      _clearError();
      notifyListeners();
    }
  }

  /// 清除選擇
  void clearSelection() {
    _selectedOption = null;
    _clearError();
    notifyListeners();
  }

  /// 執行搜索
  Future<void> performSearch() async {
    if (_selectedOption == null) {
      _setError('Please select a destination first');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // 模擬搜索延遲
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 這裡可以添加實際的搜索邏輯
      // 例如：調用 API、更新結果等
      
      debugPrint('Search performed for: ${_selectedOption!.name}');
      
    } catch (e) {
      _setError('Search failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 多語言關鍵字搜索
  List<SearchResult> searchByKeywords(String query, {int? limit}) {
    return SearchService.performSearch(
      query,
      limit: limit ?? 10,
    );
  }

  /// 獲取搜索建議
  List<String> getSearchSuggestions(String query, {int limit = 5}) {
    return SearchService.getSuggestions(query, limit: limit);
  }

  /// 更新表單資料
  void updateFormData(String key, dynamic value) {
    _formData[key] = value;
    notifyListeners();
  }

  /// 批量更新表單資料
  void updateFormDataBatch(Map<String, dynamic> data) {
    _formData.addAll(data);
    notifyListeners();
  }

  /// 清除表單資料
  void clearFormData() {
    _formData.clear();
    notifyListeners();
  }

  /// 獲取表單資料
  T? getFormData<T>(String key) {
    return _formData[key] as T?;
  }

  /// 驗證表單
  bool validateForm() {
    _clearError();
    
    if (_selectedOption == null) {
      _setError('Please select a destination');
      return false;
    }

    // 根據選項類型進行不同的驗證
    switch (_selectedOption!.type) {
      case SearchOptionType.station:
        return _validateStationForm();
      case SearchOptionType.attraction:
        return _validateAttractionForm();
    }
  }

  /// 驗證車站表單
  bool _validateStationForm() {
    final departure = getFormData<String>('departure');
    final destination = getFormData<String>('destination');
    final departureDate = getFormData<DateTime>('departureDate');
    final adultCount = getFormData<int>('adultCount') ?? 0;

    if (departure == null || departure.isEmpty) {
      _setError('Please select departure station');
      return false;
    }

    if (destination == null || destination.isEmpty) {
      _setError('Please select destination station');
      return false;
    }

    if (departure == destination) {
      _setError('Departure and destination cannot be the same');
      return false;
    }

    if (departureDate == null) {
      _setError('Please select departure date');
      return false;
    }

    if (departureDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      _setError('Departure date cannot be in the past');
      return false;
    }

    if (adultCount < 1) {
      _setError('At least one adult passenger is required');
      return false;
    }

    return true;
  }

  /// 驗證景點表單
  bool _validateAttractionForm() {
    final tickets = getFormData<List<Map<String, dynamic>>>('tickets') ?? [];
    final email = getFormData<String>('email');

    if (tickets.isEmpty) {
      _setError('Please add at least one ticket');
      return false;
    }

    for (int i = 0; i < tickets.length; i++) {
      final ticket = tickets[i];
      final familyName = ticket['familyName'] as String?;
      final givenName = ticket['givenName'] as String?;
      final selectedDate = ticket['selectedDate'] as DateTime?;
      final timeSlot = ticket['timeSlot'] as String?;

      if (familyName == null || familyName.isEmpty) {
        _setError('Please enter family name for ticket ${i + 1}');
        return false;
      }

      if (givenName == null || givenName.isEmpty) {
        _setError('Please enter given name for ticket ${i + 1}');
        return false;
      }

      if (selectedDate == null) {
        _setError('Please select date for ticket ${i + 1}');
        return false;
      }

      if (timeSlot == null || timeSlot.isEmpty) {
        _setError('Please select time slot for ticket ${i + 1}');
        return false;
      }
    }

    if (email == null || email.isEmpty) {
      _setError('Please enter email address');
      return false;
    }

    // 簡單的 email 驗證
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _setError('Please enter a valid email address');
      return false;
    }

    return true;
  }

  /// 提交申請
  Future<void> submitApplication() async {
    if (!validateForm()) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // 模擬提交延遲
      await Future.delayed(const Duration(seconds: 2));
      
      // 這裡可以添加實際的提交邏輯
      // 例如：調用 API、處理支付等
      
      debugPrint('Application submitted for: ${_selectedOption!.name}');
      debugPrint('Form data: $_formData');
      
      // 清除表單資料
      clearFormData();
      
    } catch (e) {
      _setError('Submission failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 重置所有狀態
  void reset() {
    _selectedOption = null;
    _isLoading = false;
    _errorMessage = null;
    _formData.clear();
    notifyListeners();
  }

  /// 添加到搜索歷史
  void _addToHistory(SearchOption option) {
    // 移除已存在的相同選項
    _searchHistory.removeWhere((item) => item.id == option.id);
    
    // 添加到開頭
    _searchHistory.insert(0, option);
    
    // 限制歷史記錄數量
    if (_searchHistory.length > _maxHistoryCount) {
      _searchHistory = _searchHistory.take(_maxHistoryCount).toList();
    }
  }

  /// 清除搜索歷史
  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  /// 從搜索歷史中移除項目
  void removeFromHistory(String optionId) {
    _searchHistory.removeWhere((item) => item.id == optionId);
    notifyListeners();
  }

  /// 設置載入狀態
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 設置錯誤訊息
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// 清除錯誤訊息
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 獲取當前選項的元數據
  Map<String, dynamic>? getCurrentMetadata() {
    return _selectedOption?.metadata;
  }

  /// 獲取當前選項的關鍵字
  List<String> getCurrentKeywords() {
    return _selectedOption?.keywords ?? [];
  }

  /// 檢查是否支援特定服務
  bool supportsService(String serviceName) {
    final metadata = getCurrentMetadata();
    if (metadata == null) return false;
    
    final services = metadata['services'] as List<dynamic>?;
    return services?.contains(serviceName) ?? false;
  }

  /// 獲取票價資訊
  Map<String, int>? getTicketPrices() {
    final metadata = getCurrentMetadata();
    if (metadata == null) return null;
    
    final ticketPrice = metadata['ticketPrice'] as Map<String, dynamic>?;
    if (ticketPrice == null) return null;
    
    return {
      'adult': ticketPrice['adult'] as int? ?? 0,
      'child': ticketPrice['child'] as int? ?? 0,
    };
  }

  /// 計算總價格
  double calculateTotalPrice() {
    if (_selectedOption?.type == SearchOptionType.attraction) {
      return _calculateAttractionPrice();
    } else if (_selectedOption?.type == SearchOptionType.station) {
      return _calculateStationPrice();
    }
    return 0.0;
  }

  /// 計算景點門票總價
  double _calculateAttractionPrice() {
    final tickets = getFormData<List<Map<String, dynamic>>>('tickets') ?? [];
    final prices = getTicketPrices();
    if (prices == null) return 0.0;
    
    double total = 0.0;
    for (final ticket in tickets) {
      final isAdult = ticket['isAdult'] as bool? ?? true;
      total += isAdult ? prices['adult']! : prices['child']!;
    }
    
    return total;
  }

  /// 計算車站票券總價
  double _calculateStationPrice() {
    // 這裡可以根據實際的火車票價格邏輯來計算
    // 目前返回固定價格作為示例
    final adultCount = getFormData<int>('adultCount') ?? 0;
    final childCount = getFormData<int>('childCount') ?? 0;
    
    return (adultCount * 50.0) + (childCount * 25.0); // 示例價格
  }

  @override
  void dispose() {
    // 清理資源
    super.dispose();
  }
}
