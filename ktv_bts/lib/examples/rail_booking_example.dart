import 'package:intl/intl.dart';
import '../services/rail_booking_service.dart';
import '../models/rail_search_criteria.dart';

/// 鐵路預訂服務使用範例
class RailBookingExample {
  static final _service = RailBookingService.defaultInstance();

  /// 基本搜尋範例
  static Future<void> basicSearchExample() async {
    print('🚀 開始基本搜尋範例');
    
    // 創建搜尋條件
    final searchDate = DateFormat("yyyy-MM-dd")
        .format(DateTime.now().add(const Duration(days: 7)));
    
    final criteria = RailSearchCriteria(
      from: "Frankfurt",
      to: "Berlin",
      date: searchDate,
      time: "08:00",
      adult: 1,
      child: 0,
    );

    try {
      // 執行搜尋
      final result = await _service.searchAndGetResults(criteria);
      
      if (result.success) {
        print('✅ 搜尋成功！');
        print('📊 找到 ${result.data?.solutions.length ?? 0} 個班次');
        
        // 顯示前 3 個班次的基本信息
        final solutions = result.data?.solutions.take(3) ?? [];
        for (int i = 0; i < solutions.length; i++) {
          print('🚄 班次 ${i + 1}: ${solutions.elementAt(i)}');
        }
      } else {
        print('❌ 搜尋失敗: ${result.errorMessage}');
      }
    } catch (e) {
      print('💥 搜尋異常: $e');
    }
  }

  /// 分步驟搜尋範例
  static Future<void> stepByStepSearchExample() async {
    print('🚀 開始分步驟搜尋範例');
    
    final searchDate = DateFormat("yyyy-MM-dd")
        .format(DateTime.now().add(const Duration(days: 14)));
    
    final criteria = RailSearchCriteria(
      from: "Munich",
      to: "Zurich",
      date: searchDate,
      time: "14:30",
      adult: 2,
      child: 1,
    );

    try {
      // 步驟 1: 搜尋火車班次
      print('📍 步驟 1: 搜尋火車班次');
      final searchResult = await _service.searchTrains(criteria);
      
      if (!searchResult.success) {
        print('❌ 搜尋失敗: ${searchResult.errorMessage}');
        return;
      }
      
      print('✅ 搜尋成功，Async Key: ${searchResult.asyncKey}');
      
      // 步驟 2: 獲取結果
      print('📍 步驟 2: 獲取搜尋結果');
      final resultResponse = await _service.getAsyncResult(
        searchResult.asyncKey!,
        maxRetries: 3,
        retryDelay: const Duration(seconds: 2),
      );
      
      if (resultResponse.success) {
        print('✅ 獲取結果成功！');
        print('📊 找到 ${resultResponse.data?.solutions.length ?? 0} 個班次');
        
        // 顯示原始響應數據
        print('📋 原始響應數據:');
        print(resultResponse.data?.rawData.toString() ?? '無數據');
      } else {
        print('❌ 獲取結果失敗: ${resultResponse.errorMessage}');
      }
    } catch (e) {
      print('💥 搜尋異常: $e');
    }
  }

  /// 多種搜尋條件範例
  static Future<void> multipleSearchCriteriaExample() async {
    print('🚀 開始多種搜尋條件範例');
    
    final searchDate = DateFormat("yyyy-MM-dd")
        .format(DateTime.now().add(const Duration(days: 21)));
    
    // 測試不同的城市組合
    final searchCriteria = [
      RailSearchCriteria(
        from: "Paris",
        to: "Lyon",
        date: searchDate,
        time: "09:00",
        adult: 1,
      ),
      RailSearchCriteria(
        from: "Rome",
        to: "Milan",
        date: searchDate,
        time: "12:00",
        adult: 2,
        child: 1,
      ),
      RailSearchCriteria(
        from: "Madrid",
        to: "Barcelona",
        date: searchDate,
        time: "16:30",
        adult: 1,
        senior: 1,
      ),
    ];

    for (int i = 0; i < searchCriteria.length; i++) {
      final criteria = searchCriteria[i];
      print('🔍 搜尋 ${i + 1}: ${criteria.from} → ${criteria.to}');
      
      try {
        final result = await _service.searchTrains(criteria);
        
        if (result.success) {
          print('✅ 搜尋 ${i + 1} 成功，Async Key: ${result.asyncKey}');
        } else {
          print('❌ 搜尋 ${i + 1} 失敗: ${result.errorMessage}');
        }
      } catch (e) {
        print('💥 搜尋 ${i + 1} 異常: $e');
      }
      
      // 避免過於頻繁的請求
      if (i < searchCriteria.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// 運行所有範例
  static Future<void> runAllExamples() async {
    print('🎯 開始運行鐵路預訂服務範例\n');
    
    try {
      await basicSearchExample();
      print('\n' + '='*50 + '\n');
      
      await stepByStepSearchExample();
      print('\n' + '='*50 + '\n');
      
      await multipleSearchCriteriaExample();
      
      print('\n🎉 所有範例運行完成！');
    } catch (e) {
      print('💥 範例運行異常: $e');
    } finally {
      // 清理資源
      _service.dispose();
    }
  }
}

/// 主函數用於測試
void main() async {
  await RailBookingExample.runAllExamples();
}
