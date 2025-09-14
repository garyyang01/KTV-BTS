import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/rail_booking_service.dart';
import '../models/rail_search_criteria.dart';
import '../models/rail_api_response.dart';
import '../models/train_solution.dart';
import '../widgets/rail_solution_card.dart';
import 'train_selection_page.dart';

/// 鐵路搜尋測試頁面
/// 提供 UI 介面來測試 G2Rail API 搜尋功能
class RailSearchTestPage extends StatefulWidget {
  const RailSearchTestPage({super.key});

  @override
  State<RailSearchTestPage> createState() => _RailSearchTestPageState();
}

class _RailSearchTestPageState extends State<RailSearchTestPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController(text: 'ST_LX225YVP');
  final _toController = TextEditingController(text: 'ST_E7GGGP8J');
  final _dateController = TextEditingController();
  final _timeController = TextEditingController(text: '12:00');
  final _adultController = TextEditingController(text: '1');
  final _childController = TextEditingController(text: '0');
  final _juniorController = TextEditingController(text: '0');
  final _seniorController = TextEditingController(text: '0');
  final _infantController = TextEditingController(text: '0');

  late RailBookingService _railService;
  bool _isLoading = false;
  String _statusMessage = '';
  AsyncResultResponse? _searchResults;
  List<TrainSolution> _trainSolutions = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _railService = RailBookingService.defaultInstance();
    
    // 設定預設日期為 2025-09-18
    final defaultDate = DateTime(2025, 9, 18);
    _dateController.text = DateFormat('yyyy-MM-dd').format(defaultDate);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _adultController.dispose();
    _childController.dispose();
    _juniorController.dispose();
    _seniorController.dispose();
    _infantController.dispose();
    _railService.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在搜尋火車班次...';
      _searchResults = null;
      _trainSolutions = [];
      _errorMessage = '';
    });

    try {
      // 創建搜尋條件
      final criteria = RailSearchCriteria(
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        adult: int.tryParse(_adultController.text) ?? 1,
        child: int.tryParse(_childController.text) ?? 0,
        junior: int.tryParse(_juniorController.text) ?? 0,
        senior: int.tryParse(_seniorController.text) ?? 0,
        infant: int.tryParse(_infantController.text) ?? 0,
      );

      setState(() {
        _statusMessage = '搜尋條件: ${criteria.from} → ${criteria.to}';
      });

      // 執行搜尋
      final result = await _railService.searchAndGetResults(criteria);

      setState(() {
        _isLoading = false;
        
        if (result.success) {
          _searchResults = result.data;
          _trainSolutions = _parseTrainSolutions(result.data?.solutions ?? []);
          _statusMessage = '搜尋完成！找到 ${_trainSolutions.length} 個班次選項';
          _errorMessage = '';
        } else {
          _errorMessage = result.errorMessage ?? '搜尋失敗';
          _statusMessage = '搜尋失敗';
          _searchResults = null;
          _trainSolutions = [];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜尋異常: ${e.toString()}';
        _statusMessage = '搜尋異常';
        _searchResults = null;
        _trainSolutions = [];
      });
    }
  }

  /// 解析火車班次解決方案
  List<TrainSolution> _parseTrainSolutions(List<dynamic> solutions) {
    final List<TrainSolution> trainSolutions = [];
    
    print('🔍 開始解析 ${solutions.length} 個班次解決方案');
    
    for (int i = 0; i < solutions.length; i++) {
      var solution = solutions[i];
      print('🔍 解析第 ${i + 1} 個解決方案: ${solution.runtimeType}');
      
      if (solution is Map<String, dynamic>) {
        print('🔍 解決方案內容: ${solution.keys.toList()}');
        
        try {
          // 檢查是否有實際的 solutions 數據
          List<dynamic> solutionsData = solution['solutions'] as List<dynamic>? ?? [];
          print('🔍 檢查 solutions 數據: ${solutionsData.length} 個項目');
          
          // 只處理有實際數據的班次
          if (solutionsData.isNotEmpty) {
            // 檢查是否為有效的班次解決方案
            bool hasRequiredFields = false;
            
            // 檢查多種可能的結構
            if (solution.containsKey('offers') && solution.containsKey('trains')) {
              hasRequiredFields = true;
              print('✅ 找到標準結構 (offers + trains)');
            } else if (solution.containsKey('railway')) {
              hasRequiredFields = true;
              print('✅ 找到 railway 結構');
            } else if (solution.containsKey('carrier')) {
              hasRequiredFields = true;
              print('✅ 找到 carrier 結構');
            } else {
              print('❌ 未找到標準結構，嘗試直接解析');
              hasRequiredFields = true; // 嘗試直接解析
            }
            
            if (hasRequiredFields) {
              final trainSolution = TrainSolution.fromJson(solution);
              // 只有當 TrainSolution 有實際的 offers 或 trains 時才添加
              if (trainSolution.offers.isNotEmpty || trainSolution.trains.isNotEmpty) {
                trainSolutions.add(trainSolution);
                print('✅ 成功解析班次解決方案: ${trainSolution.carrierDescription} (${trainSolution.offers.length} offers, ${trainSolution.trains.length} trains)');
              } else {
                print('⚠️ 跳過空數據的班次解決方案: ${trainSolution.carrierDescription}');
              }
            }
          } else {
            print('⚠️ 跳過沒有 solutions 數據的班次');
          }
        } catch (e) {
          print('❌ 解析班次解決方案時發生錯誤: $e');
          print('❌ 解決方案內容: $solution');
        }
      } else {
        print('❌ 解決方案不是 Map 類型: ${solution.runtimeType}');
      }
    }
    
    print('🎯 最終解析結果: ${trainSolutions.length} 個有效的班次解決方案');
    return trainSolutions;
  }

  /// 導航到班次選擇頁面
  void _navigateToTrainSelection() {
    if (_trainSolutions.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrainSelectionPage(
          solutions: _trainSolutions,
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔍 火車班次搜尋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 出發地和目的地
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'From Rome Termini Central Station',
                        hintText: 'ST_LX225YVP',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入出發地';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To Catania Centrale Station',
                        hintText: 'ST_E7GGGP8J',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入目的地';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 日期和時間
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: '出發日期',
                        hintText: 'yyyy-MM-dd',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請選擇出發日期';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: '出發時間',
                        hintText: 'HH:mm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入出發時間';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 乘客數量
              Text(
                '👥 乘客數量',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adultController,
                      decoration: const InputDecoration(
                        labelText: '成人',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final count = int.tryParse(value ?? '');
                        if (count == null || count < 0) {
                          return '請輸入有效的成人數量';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _childController,
                      decoration: const InputDecoration(
                        labelText: '兒童',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final count = int.tryParse(value ?? '');
                        if (count == null || count < 0) {
                          return '請輸入有效的兒童數量';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _juniorController,
                      decoration: const InputDecoration(
                        labelText: '青少年',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final count = int.tryParse(value ?? '');
                        if (count == null || count < 0) {
                          return '請輸入有效的青少年數量';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seniorController,
                      decoration: const InputDecoration(
                        labelText: '長者',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final count = int.tryParse(value ?? '');
                        if (count == null || count < 0) {
                          return '請輸入有效的長者數量';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _infantController,
                      decoration: const InputDecoration(
                        labelText: '嬰兒',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final count = int.tryParse(value ?? '');
                        if (count == null || count < 0) {
                          return '請輸入有效的嬰兒數量';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 8), // 佔位符保持對齊
                ],
              ),
              const SizedBox(height: 24),

              // 搜尋按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _performSearch,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                  label: Text(_isLoading ? '搜尋中...' : '開始搜尋'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_statusMessage.isEmpty && _errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 搜尋狀態',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_trainSolutions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🚄 搜尋結果 (${_trainSolutions.length} 個班次選項)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _navigateToTrainSelection,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('選擇班次'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 顯示班次摘要
            ..._trainSolutions.asMap().entries.map((entry) {
              final index = entry.key;
              final solution = entry.value;
              return _buildSolutionSummary(solution, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionSummary(TrainSolution solution, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 營運商標題
          Row(
            children: [
              Text(
                '${index + 1}. ${solution.carrierDescription}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${solution.offers.length} 種票價',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 火車班次列表
          if (solution.trains.isNotEmpty) ...[
            Text(
              '🚂 火車班次',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...solution.trains.asMap().entries.map((entry) {
              final trainIndex = entry.key;
              final train = entry.value;
              return _buildTrainSummary(train, trainIndex);
            }),
            const SizedBox(height: 16),
          ],
          
          // 價格信息
          Row(
            children: [
              Text(
                '💰 價格範圍: ',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getLowestPrice(solution),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainSummary(TrainInfo train, int trainIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // 車次信息
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  train.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  train.typeName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // 出發信息
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(train.departure),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  train.from.localName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // 箭頭
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
          ),
          
          // 到達信息
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(train.arrival),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  train.to.localName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // 時間和停靠站信息
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  train.formattedDuration,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (train.stops.isNotEmpty)
                  Text(
                    '${train.stops.length} 站',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLowestPrice(TrainSolution solution) {
    int lowestCents = 999999;
    String currency = 'EUR';
    
    for (var offer in solution.offers) {
      for (var service in offer.services) {
        if (service.price.cents < lowestCents) {
          lowestCents = service.price.cents;
          currency = service.price.currency;
        }
      }
    }
    
    return '$currency ${(lowestCents / 100).toStringAsFixed(2)}';
  }

  void _showSolutionDetails(dynamic solution, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('班次 $index 詳細信息'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (solution is Map) ...[
                if (solution.containsKey('from') && solution.containsKey('to'))
                  _buildDetailRow('路線', '${solution['from']} → ${solution['to']}'),
                if (solution.containsKey('departure'))
                  _buildDetailRow('出發時間', solution['departure']),
                if (solution.containsKey('arrival'))
                  _buildDetailRow('到達時間', solution['arrival']),
                if (solution.containsKey('duration'))
                  _buildDetailRow('行程時間', solution['duration']),
                if (solution.containsKey('train_number'))
                  _buildDetailRow('車次', solution['train_number']),
                if (solution.containsKey('carrier'))
                  _buildDetailRow('營運商', solution['carrier']),
                if (solution.containsKey('price'))
                  _buildDetailRow('價格', '€${solution['price']}'),
              ],
              const SizedBox(height: 16),
              Text(
                '原始數據:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  solution.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚄 鐵路搜尋測試'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchForm(),
            const SizedBox(height: 16),
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildResultsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
