# 鐵路預訂服務 (RailBookingService)

## 概述

`RailBookingService` 是一個整合 G2Rail API 的服務，用於搜尋和預訂火車票。支援全球多個鐵路系統，包括德國鐵路、中國高鐵、義大利鐵路等。

## 主要功能

- 🔍 **火車班次搜尋**: 根據出發地、目的地、日期和時間搜尋可用班次
- ⏳ **非同步結果處理**: 處理 G2Rail API 的非同步搜尋機制
- 🔐 **MD5 認證**: 自動處理 API 認證和簽名
- 🔄 **自動重試**: 智能重試機制處理暫時性錯誤
- 📊 **詳細日誌**: 完整的請求和響應日誌記錄

## 快速開始

### 1. 基本使用

```dart
import 'package:ktv_bts/services/rail_booking_service.dart';
import 'package:ktv_bts/models/rail_search_criteria.dart';

// 創建服務實例
final railService = RailBookingService.defaultInstance();

// 創建搜尋條件
final criteria = RailSearchCriteria(
  from: "Frankfurt",
  to: "Berlin",
  date: "2024-01-15",
  time: "08:00",
  adult: 1,
  child: 0,
);

// 執行完整搜尋流程
final result = await railService.searchAndGetResults(criteria);

if (result.success) {
  print('找到 ${result.data?.solutions.length} 個班次');
  // 處理搜尋結果
} else {
  print('搜尋失敗: ${result.errorMessage}');
}
```

### 2. 分步驟搜尋

```dart
// 步驟 1: 搜尋火車班次
final searchResult = await railService.searchTrains(criteria);

if (searchResult.success) {
  // 步驟 2: 獲取搜尋結果
  final result = await railService.getAsyncResult(
    searchResult.asyncKey!,
    maxRetries: 5,
    retryDelay: Duration(seconds: 3),
  );
  
  // 處理結果
}
```

## API 規格

### 搜尋火車班次 API

**端點**: `GET /api/v2/online_solutions/?{query_params}`

**參數**:
- `from`: 出發城市
- `to`: 目的地城市
- `date`: 日期 (yyyy-MM-dd 格式)
- `time`: 時間 (HH:mm 格式)
- `adult`: 成人數量
- `child`: 兒童數量
- `junior`: 青少年數量
- `senior`: 長者數量
- `infant`: 嬰兒數量

**響應**:
```json
{
  "async": "async_key_for_results"
}
```

### 獲取非同步結果 API

**端點**: `GET /api/v2/async_results/{async_key}`

**參數**:
- `async_key`: 從搜尋 API 返回的密鑰

**響應狀態碼**:
- `200`: 成功獲取結果
- `202`: 結果仍在處理中，需要重試

**成功響應**:
```json
{
  "solutions": [
    {
      "id": "solution_id",
      "price": 89.50,
      "currency": "EUR",
      "segments": [
        {
          "from": "Frankfurt",
          "to": "Berlin",
          "departure": "2024-01-15T08:30:00",
          "arrival": "2024-01-15T12:45:00",
          "duration": "4h15m",
          "train_number": "ICE 1234",
          "carrier": "DB"
        }
      ]
    }
  ]
}
```

## 認證機制

G2Rail API 使用 MD5 哈希簽名進行認證：

1. 收集所有請求參數
2. 添加時間戳記 (Unix timestamp)
3. 添加 API Key
4. 按字母順序排序參數
5. 串接參數值和 Secret
6. 生成 MD5 哈希作為 Authorization

**認證標頭**:
```
From: {API_KEY}
Authorization: {MD5_HASH}
Date: {HTTP_DATE}
Content-Type: application/json
Api-Locale: zh-TW
```

## 配置

### 測試環境憑證
- **Base URL**: `http://alpha-api.g2rail.com`
- **API Key**: `fa656e6b99d64f309d72d6a8e7284953`
- **Secret**: `9a52b1f7-7c96-4305-8569-1016a55048bc`

### 自定義配置

```dart
final service = RailBookingService(
  httpClient: http.Client(),
  baseUrl: 'https://your-api-endpoint.com',
  apiKey: 'your-api-key',
  secret: 'your-secret',
);
```

## 錯誤處理

服務提供完整的錯誤處理機制：

```dart
try {
  final result = await railService.searchAndGetResults(criteria);
  
  if (!result.success) {
    switch (result.statusCode) {
      case 401:
        print('認證失敗，請檢查 API 憑證');
        break;
      case 202:
        print('結果仍在處理中');
        break;
      default:
        print('API 錯誤: ${result.errorMessage}');
    }
  }
} catch (e) {
  if (e is AsyncResultPendingException) {
    print('結果處理超時');
  } else {
    print('網路錯誤: $e');
  }
}
```

## 支援的城市

- **德國**: Frankfurt, Berlin, Munich, Hamburg
- **法國**: Paris, Lyon, Marseille, Nice
- **義大利**: Rome, Milan, Venice, Florence
- **西班牙**: Madrid, Barcelona, Seville, Valencia
- **瑞士**: Zurich, Geneva, Basel, Bern
- **奧地利**: Vienna, Salzburg, Innsbruck
- **其他**: 支援全球 50+ 個鐵路系統

## 範例代碼

查看 `lib/examples/rail_booking_example.dart` 獲取完整的使用範例。

## 測試

運行測試：
```bash
flutter test test/services/rail_booking_service_test.dart
```

## 注意事項

1. **SSL 憑證**: 開發環境會忽略 SSL 憑證驗證，生產環境需要配置有效憑證
2. **API 限制**: 請注意 G2Rail API 的請求頻率限制
3. **時區**: 所有時間都使用 UTC 時區
4. **重試機制**: 預設最多重試 5 次，每次間隔 3 秒

## 故障排除

### 常見問題

1. **401 Unauthorized**
   - 檢查 API Key 和 Secret 是否正確
   - 確認時間戳記是否準確（服務器時間差異不能超過 5 分鐘）

2. **202 持續返回**
   - 增加重試次數和延遲時間
   - 某些複雜路線可能需要更長處理時間

3. **SSL 憑證錯誤**
   - 開發環境：服務會自動忽略 SSL 憑證
   - 生產環境：確保使用有效的 SSL 憑證

4. **中文字符問題**
   - 服務會自動使用 UTF-8 解碼處理中文響應
