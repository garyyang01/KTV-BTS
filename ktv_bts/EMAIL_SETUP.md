# Email 功能設定說明

## 功能概述
- ✅ 點擊按鈕寄信給老闆 (baluce@gmail.com)
- ✅ 每 30 秒輪詢檢查回信
- ✅ 收到回信時發送通知
- ✅ 30 分鐘後自動停止輪詢

## 需要設定的部分

### 1. 修改 `lib/services/email_service.dart` 中的 Email 設定：

```dart
// 第 18-20 行，替換為實際的發信信箱設定
static const String _appEmail = 'e1z2r3a4@gmail.com';
static const String _appPassword = 'okxh irzp zkkz pddo';  // 使用應用程式密碼，不是一般密碼
```

### 2. Gmail 設定 (建議使用 Gmail)：
1. 開啟 Gmail 的「兩步驟驗證」
2. 產生「應用程式密碼」
3. 將應用程式密碼填入 `_appPassword`

## 測試方法

1. 執行 App：`flutter run`
2. 點擊「申請門票」按鈕
3. 系統會寄信給 baluce@gmail.com
4. 老闆回覆包含訂單編號的郵件時，App 會發通知

## 訂單編號格式
`ORDER_1694599234567` (ORDER_ + 時間戳記)

## 注意事項
- 需要網路連線才能寄信和檢查回信
- 建議在實際裝置上測試通知功能
- 輪詢間隔為 30 秒，避免過度請求