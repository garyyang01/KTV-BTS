# G2Rail API 整合文件

## 概述

G2Rail 是一個全球鐵路票務聚合平台，提供跨國鐵路系統的搜尋、預訂、確認和下載服務。支援的鐵路系統包括：
- 德國鐵路 (DB Deutsche Bahn)
- 中國高鐵 (China Railway)
- 義大利鐵路 (Trenitalia)
- 西班牙鐵路 (Renfe)
- 日本鐵路 (JR)
- 台灣高鐵
- 瑞士聯邦鐵路 (SBB)
- 奧地利聯邦鐵路 (ÖBB)
- 挪威國家鐵路 (NSB)
- 歐洲各國 Flixbus
- 美國、加拿大、土耳其、巴西等

## API 文件與認證資訊

### 官方文件
- **URL**: https://docs.g2rail.com/en/pages/00_overview
- **登入帳號**: grail
- **登入密碼**: bcf868ed

### API 認證憑證
- **Base URL**: `http://alpha-api.g2rail.com`
- **API Key**: `fa656e6b99d64f309d72d6a8e7284953`
- **Secret**: `9a52b1f7-7c96-4305-8569-1016a55048bc`

> ⚠️ **注意**: 這些是測試環境憑證。生產環境需要向 G2Rail 申請正式憑證。

## API 認證機制

G2Rail 使用 MD5 哈希簽名進行 API 認證。

### 認證步驟
1. 收集所有請求參數
2. 添加時間戳記 (Unix timestamp)
3. 添加 API Key
4. 按字母順序排序參數
5. 串接參數值和 Secret
6. 生成 MD5 哈希作為 Authorization

### 認證標頭
```
From: {API_KEY}
Authorization: {MD5_HASH}
Date: {HTTP_DATE}
Content-Type: application/json
Api-Locale: zh-TW
```

## 主要 API 端點

### 1. 搜尋火車班次
```
GET /api/v2/online_solutions/?{query_params}
```

**參數**:
- `from`: 出發城市 (如 "Frankfurt")
- `to`: 目的地城市 (如 "Berlin")
- `date`: 日期 (yyyy-MM-dd 格式)
- `time`: 時間 (HH:mm 格式)
- `adult`: 成人數量
- `child`: 兒童數量
- `junior`: 青少年數量
- `senior`: 長者數量
- `infant`: 嬰兒數量

**響應**: 返回 `async` 密鑰，用於非同步查詢結果

### 2. 獲取非同步結果
```
GET /api/v2/async_results/{async_key}
```

**參數**:
- `async_key`: 從搜尋 API 返回的密鑰

**響應**: 返回實際的火車班次、路線和價格信息

## Flutter/Dart 實作

### 依賴項設置

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  crypto: ^3.0.6    # MD5 哈希
  http: ^1.5.0      # HTTP 請求
  intl: ^0.20.2     # 日期格式化
```

### 搜尋參數模型

```dart
class SearchCriteria {
  final String from;
  final String to;
  final String date;
  final String time;
  final int adult;
  final int child;
  final int junior;
  final int senior;
  final int infant;

  SearchCriteria({
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    this.adult = 1,
    this.child = 0,
    this.junior = 0,
    this.senior = 0,
    this.infant = 0,
  });

  String toQuery() {
    return "from=$from&to=$to&date=$date&time=$time"
        "&adult=$adult&child=$child&junior=$junior"
        "&senior=$senior&infant=$infant";
  }

  Map<String, dynamic> toMap() {
    return {
      "from": from,
      "to": to,
      "date": date,
      "time": time,
      "adult": adult,
      "child": child,
      "junior": junior,
      "senior": senior,
      "infant": infant,
    };
  }
}
```

### G2Rail API 客戶端

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class GrailApiClient {
  final String baseUrl;
  final String apiKey;
  final String secret;
  final http.Client httpClient;

  GrailApiClient({
    required this.httpClient,
    required this.baseUrl,
    required this.apiKey,
    required this.secret,
  });

  /// 生成認證標頭
  Map<String, String> getAuthorizationHeaders(Map<String, dynamic> params) {
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
  Future<String> searchSolutions(SearchCriteria criteria) async {
    final solutionUrl = '$baseUrl/api/v2/online_solutions/?${criteria.toQuery()}';
    
    final response = await httpClient.get(
      Uri.parse(solutionUrl),
      headers: getAuthorizationHeaders(criteria.toMap()),
    );

    if (response.statusCode != 200) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body);
    return json['async'] as String;
  }

  /// 獲取非同步結果
  Future<Map<String, dynamic>> getAsyncResult(String asyncKey) async {
    final asyncResultUrl = '$baseUrl/api/v2/async_results/$asyncKey';
    
    final response = await httpClient.get(
      Uri.parse(asyncResultUrl),
      headers: getAuthorizationHeaders({"async_key": asyncKey}),
    );

    if (response.statusCode == 202) {
      // 結果還在處理中
      throw AsyncResultPendingException('Result is still processing');
    }

    if (response.statusCode != 200) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

class AsyncResultPendingException implements Exception {
  final String message;
  AsyncResultPendingException(this.message);
}
```

### 使用範例

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'G2Rail Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'G2Rail Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  /// 創建忽略 SSL 憑證的 HTTP 客戶端（開發環境）
  Client baseClient() {
    HttpClient httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          return true;
        };
    Client c = IOClient(httpClient);
    return c;
  }

  void _searchTrains() async {
    try {
      print('Starting API call...');
      
      String baseUrl = "http://alpha-api.g2rail.com";
      var apiClient = GrailApiClient(
        httpClient: baseClient(),
        baseUrl: baseUrl,
        apiKey: "fa656e6b99d64f309d72d6a8e7284953",
        secret: "9a52b1f7-7c96-4305-8569-1016a55048bc",
      );
      
      var searchDate = DateFormat("yyyy-MM-dd")
          .format(DateTime.now().add(const Duration(days: 7)));
      
      print('Searching from Frankfurt to Berlin on $searchDate at 08:00');
      
      var criteria = SearchCriteria(
        from: "Frankfurt",
        to: "Berlin",
        date: searchDate,
        time: "08:00",
        adult: 1,
      );
      
      // 步驟 1: 獲取 async key
      var asyncKey = await apiClient.searchSolutions(criteria);
      print('API call successful! Async key: $asyncKey');
      
      // 步驟 2: 等待並獲取結果（需要輪詢）
      await Future.delayed(Duration(seconds: 3));
      
      try {
        var results = await apiClient.getAsyncResult(asyncKey);
        print('Got results: $results');
      } catch (e) {
        if (e is AsyncResultPendingException) {
          print('Results still processing, please wait...');
        } else {
          print('Error getting results: $e');
        }
      }
      
    } catch (e) {
      print('API Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('點擊按鈕搜尋火車班次'),
            const SizedBox(height: 20),
            Text(
              'Frankfurt → Berlin',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _searchTrains,
        tooltip: '搜尋',
        child: const Icon(Icons.search),
      ),
    );
  }
}
```

## 常見問題

### SSL 憑證錯誤
開發環境中可能遇到 SSL 憑證驗證失敗，可以暫時忽略憑證驗證：
```dart
HttpClient httpClient = HttpClient();
httpClient.badCertificateCallback = 
    (X509Certificate cert, String host, int port) => true;
```
⚠️ 注意：僅在開發環境使用，生產環境必須使用有效憑證

### API 返回 401 Unauthorized
檢查：
1. API Key 和 Secret 是否正確
2. 時間戳記是否正確（服務器時間差異不能超過 5 分鐘）
3. MD5 哈希生成邏輯是否正確

### 非同步結果返回 202
這表示結果還在處理中，需要：
1. 等待幾秒後重試
2. 實現輪詢機制
3. 某些複雜路線可能需要更長處理時間

### 中文字符顯示問題
使用 UTF-8 解碼：
```dart
jsonDecode(utf8.decode(response.bodyBytes))
```

## 支援的城市範例
- Frankfurt (法蘭克福)
- Berlin (柏林)
- Munich (慕尼黑)
- Paris (巴黎)
- Rome (羅馬)
- Milan (米蘭)
- Madrid (馬德里)
- Barcelona (巴塞羅那)
- Zurich (蘇黎世)
- Vienna (維也納)