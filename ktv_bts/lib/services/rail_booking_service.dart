import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/rail_search_criteria.dart';
import '../models/rail_api_response.dart';

/// 鐵路預訂服務
/// 整合 G2Rail API 進行火車班次搜尋和預訂
class RailBookingService {
  final String baseUrl;
  final String apiKey;
  final String secret;
  final http.Client httpClient;

  const RailBookingService({
    required this.httpClient,
    required this.baseUrl,
    required this.apiKey,
    required this.secret,
  });

  /// 創建預設的 RailBookingService 實例
  factory RailBookingService.defaultInstance({
    http.Client? httpClient,
  }) {
    // 創建忽略 SSL 憑證的 HTTP 客戶端（開發環境）
    final client = httpClient ?? _createInsecureHttpClient();
    
    return RailBookingService(
      httpClient: client,
      baseUrl: 'http://alpha-api.g2rail.com',
      apiKey: 'fa656e6b99d64f309d72d6a8e7284953',
      secret: '9a52b1f7-7c96-4305-8569-1016a55048bc',
    );
  }

  /// 創建忽略 SSL 憑證的 HTTP 客戶端（僅開發環境使用）
  static http.Client _createInsecureHttpClient() {
    HttpClient httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true; // 忽略 SSL 憑證驗證
    };
    return IOClient(httpClient);
  }

  /// 生成認證標頭
  Map<String, String> _getAuthorizationHeaders(Map<String, dynamic> params) {
    var timestamp = DateTime.now();
    params['t'] = (timestamp.millisecondsSinceEpoch ~/ 1000).toString();
    params['api_key'] = apiKey;

    // 按字母順序排序參數
    var sortedKeys = params.keys.toList()..sort((a, b) => a.compareTo(b));
    StringBuffer buffer = StringBuffer("");
    
    for (var key in sortedKeys) {
      if (params[key] is List || params[key] is Map) continue;
      buffer.write('$key=${params[key].toString()}');
    }
    buffer.write(secret);

    // 生成 MD5 哈希
    String hashString = buffer.toString();
    String authorization = md5.convert(utf8.encode(hashString)).toString();

    return {
      "From": apiKey,
      "Content-Type": 'application/json',
      "Authorization": authorization,
      "Date": HttpDate.format(timestamp),
      "Api-Locale": "zh-TW",
    };
  }

  /// 搜尋火車班次
  /// 返回 async key，用於後續獲取結果
  /// 如果 isLoading = true，會持續調用直到 isLoading = false（無限制重試）
  Future<RailApiResponse<SearchResponse>> searchTrains(
    RailSearchCriteria criteria, {
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (true) {
      try {
        attempts++;
        print('🚀 [RAIL API] 開始搜尋火車班次 (嘗試 $attempts)');
        print('📍 搜尋條件: $criteria');
        
        final solutionUrl = '$baseUrl/api/v2/online_solutions/?${criteria.toQueryString()}';
        
        print('🔗 API URL: $solutionUrl');
        
        final response = await httpClient.get(
          Uri.parse(solutionUrl),
          headers: _getAuthorizationHeaders(criteria.toMap()),
        );

        print('📊 響應狀態碼: ${response.statusCode}');

        if (response.statusCode != 200) {
          print('❌ API 錯誤: ${response.statusCode} - ${response.body}');
          return RailApiResponse.failure(
            errorMessage: 'API Error ${response.statusCode}: ${response.body}',
            statusCode: response.statusCode,
          );
        }

        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final searchResponse = SearchResponse.fromJson(json);
        
        print('🔍 搜尋響應: asyncKey=${searchResponse.asyncKey}, isLoading=${searchResponse.isLoading}');
        
        if (searchResponse.isLoading) {
          print('⏳ 搜尋仍在進行中，等待 ${retryDelay.inSeconds} 秒後重試...');
          await Future.delayed(retryDelay);
          continue;
        }
        
        print('✅ 搜尋完成，獲取 async key: ${searchResponse.asyncKey}');
        
        return RailApiResponse.success(
          data: searchResponse,
          message: '搜尋成功',
          asyncKey: searchResponse.asyncKey,
        );
      } catch (e) {
        print('❌ 搜尋異常: $e');
        print('⏳ 等待 ${retryDelay.inSeconds} 秒後重試...');
        await Future.delayed(retryDelay);
        continue;
      }
    }
  }

  /// 獲取非同步結果
  /// 使用 async key 獲取實際的搜尋結果
  /// 在 status = 200 時直接返回結果，不再重試
  Future<RailApiResponse<AsyncResultResponse>> getAsyncResult(
    String asyncKey, {
    Duration retryDelay = const Duration(seconds: 3),
    int maxRetries = 15,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        print('🔄 [RAIL API] 獲取非同步結果 (嘗試 $attempts)');
        print('🔑 Async Key: $asyncKey');
        
        final asyncResultUrl = '$baseUrl/api/v2/async_results/$asyncKey';
        
        print('🔗 API URL: $asyncResultUrl');
        
        final response = await httpClient.get(
          Uri.parse(asyncResultUrl),
          headers: _getAuthorizationHeaders({"async_key": asyncKey}),
        );

        print('📊 響應狀態碼: ${response.statusCode}');

        if (response.statusCode == 202 || response.statusCode == 423) {
          // 結果還在處理中 (202) 或非同步結果未準備好 (423)
          print('⏳ 結果仍在處理中 (${response.statusCode})，等待 ${retryDelay.inSeconds} 秒後重試...');
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          } else {
            return RailApiResponse.failure(
              errorMessage: '結果處理超時：超過最大重試次數 ($maxRetries)',
            );
          }
        }

        if (response.statusCode != 200) {
          print('❌ API 錯誤: ${response.statusCode} - ${response.body}');
          return RailApiResponse.failure(
            errorMessage: 'API Error ${response.statusCode}: ${response.body}',
            statusCode: response.statusCode,
          );
        }

        // 當 status = 200 時，直接返回結果，不再檢查載入狀態
        print('✅ 收到 status = 200，直接返回結果');
        
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        print('🔍 API 響應數據類型: ${json.runtimeType}');
        print('🔍 API 響應內容: $json');
        
        AsyncResultResponse resultResponse;
        if (json is List) {
          // 如果響應是 List，使用新的構造函數
          resultResponse = AsyncResultResponse.fromList(json);
        } else if (json is Map<String, dynamic>) {
          // 如果響應是 Map，使用原來的解析方式
          resultResponse = AsyncResultResponse.fromJson(json);
        } else {
          throw Exception('未知的 API 響應格式: ${json.runtimeType}');
        }
        
        print('✅ 成功獲取結果，包含 ${resultResponse.solutions.length} 個班次');
        
        return RailApiResponse.success(
          data: resultResponse,
          message: '成功獲取搜尋結果',
        );
      } catch (e) {
        print('❌ 獲取結果異常: $e');
        if (attempts < maxRetries) {
          print('⏳ 等待 ${retryDelay.inSeconds} 秒後重試...');
          await Future.delayed(retryDelay);
          continue;
        } else {
          return RailApiResponse.failure(
            errorMessage: '獲取結果失敗：超過最大重試次數 ($maxRetries)',
          );
        }
      }
    }
    
    return RailApiResponse.failure(
      errorMessage: '獲取結果失敗：超過最大重試次數 ($maxRetries)',
    );
  }

  /// 檢查所有項目是否都已完成載入
  bool _checkAllItemsLoaded(dynamic json) {
    try {
      if (json is List) {
        // 如果是 List，檢查每個項目
        for (var item in json) {
          if (item is Map<String, dynamic>) {
            // 檢查 loading 或 isLoading 欄位
            if (item['loading'] == true || item['isLoading'] == true) {
              print('🔍 發現載入中的項目: ${item['railway']?['name'] ?? 'Unknown'} (loading: ${item['loading']})');
              return false;
            }
          }
        }
        return true;
      } else if (json is Map<String, dynamic>) {
        // 如果是 Map，檢查 solutions 陣列
        if (json.containsKey('solutions') && json['solutions'] is List) {
          List solutions = json['solutions'];
          for (var solution in solutions) {
            if (solution is Map<String, dynamic>) {
              if (solution['loading'] == true || solution['isLoading'] == true) {
                print('🔍 發現載入中的班次: ${solution['railway']?['name'] ?? 'Unknown'} (loading: ${solution['loading']})');
                return false;
              }
            }
          }
        }
        // 也檢查頂層的 loading 或 isLoading
        if (json['loading'] == true || json['isLoading'] == true) {
          print('🔍 頂層仍在載入中 (loading: ${json['loading']})');
          return false;
        }
        return true;
      }
      return true; // 未知格式，假設已完成
    } catch (e) {
      print('❌ 檢查載入狀態時發生錯誤: $e');
      return true; // 發生錯誤時假設已完成
    }
  }

  /// 完整的搜尋流程
  /// 包含搜尋和獲取結果的完整流程
  /// 最多重試 15 次
  Future<RailApiResponse<AsyncResultResponse>> searchAndGetResults(
    RailSearchCriteria criteria, {
    Duration searchRetryDelay = const Duration(seconds: 2),
    Duration resultRetryDelay = const Duration(seconds: 3),
    int maxRetries = 15,
  }) async {
    print('🚀 [RAIL API] 開始完整搜尋流程');
    
    // 步驟 1: 搜尋火車班次（會自動處理 isLoading 邏輯，無限制重試）
    final searchResponse = await searchTrains(
      criteria,
      retryDelay: searchRetryDelay,
    );
    
    if (!searchResponse.success || searchResponse.asyncKey == null) {
      print('❌ 搜尋失敗，無法繼續');
      return RailApiResponse.failure(
        errorMessage: searchResponse.errorMessage ?? '搜尋失敗',
      );
    }
    
    print('⏳ 等待 3 秒後開始獲取結果...');
    await Future.delayed(const Duration(seconds: 3));
    
    // 步驟 2: 獲取非同步結果（最多重試 15 次）
    return await getAsyncResult(
      searchResponse.asyncKey!,
      retryDelay: resultRetryDelay,
      maxRetries: maxRetries,
    );
  }

  /// 關閉 HTTP 客戶端
  void dispose() {
    httpClient.close();
  }
}
