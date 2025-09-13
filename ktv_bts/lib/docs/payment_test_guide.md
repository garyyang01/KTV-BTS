# Stripe 支付測試指南

## 🧪 測試頁面功能

我已經為您創建了一個完整的測試頁面 `PaymentTestPage`，用來驗證我們的 Stripe 服務是否真的能收到錢。

### 📱 測試頁面功能

1. **創建支付意圖** - 測試我們的服務是否能成功調用 Stripe API
2. **確認支付** - 使用測試信用卡完成支付
3. **查詢狀態** - 檢查支付狀態
4. **清除結果** - 重置測試結果

### 🔧 Hardcoded 測試參數

```dart
final String _testCustomerName = '張三';
final bool _testIsAdult = true;
final String _testTime = 'Morning';
// 預期金額: 20.0 EUR (成人)
```

### 🎯 測試步驟

1. **啟動應用**
   ```bash
   flutter run
   ```

2. **點擊 "創建支付意圖"**
   - 檢查是否成功創建支付意圖
   - 記錄 `payment_intent_id` 和 `client_secret`

3. **檢查 Stripe Dashboard**
   - 前往: https://dashboard.stripe.com/test/payments
   - 確認是否看到新的支付意圖
   - 記錄支付意圖 ID 和狀態

4. **點擊 "確認支付"**
   - 使用 Stripe 測試信用卡完成支付
   - 檢查支付狀態是否變為 `succeeded`

5. **再次檢查 Stripe Dashboard**
   - 確認支付是否真的完成
   - 檢查金額是否正確 (20 EUR)
   - 查看支付詳情

### 💳 Stripe 測試信用卡

我們使用 Stripe 提供的測試支付方式：
- **支付方式 ID**: `pm_card_visa`
- **測試卡號**: 4242 4242 4242 4242
- **有效期**: 任何未來日期
- **CVC**: 任何 3 位數字

### 🔍 預期結果

#### 成功創建支付意圖
```json
{
  "success": true,
  "payment_intent_id": "pi_test_123456789",
  "client_secret": "pi_test_123456789_secret_abc123",
  "status": "requires_payment_method",
  "amount": 20.0,
  "currency": "EUR",
  "error_message": null
}
```

#### 成功確認支付
```json
{
  "success": true,
  "payment_intent_id": "pi_test_123456789",
  "status": "succeeded",
  "amount": 20.0,
  "currency": "EUR",
  "error_message": null
}
```

### 🚨 常見問題

1. **API 金鑰錯誤**
   - 檢查 `.env` 檔案中的 API 金鑰是否正確
   - 確認使用的是測試金鑰 (以 `pk_test_` 和 `sk_test_` 開頭)

2. **網絡錯誤**
   - 檢查網絡連接
   - 確認 Stripe API 可訪問

3. **支付失敗**
   - 檢查測試信用卡是否有效
   - 確認支付意圖狀態

### 📊 Stripe Dashboard 檢查項目

在 Stripe Dashboard 中檢查：

1. **支付意圖列表**
   - 是否出現新的支付意圖
   - 支付意圖 ID 是否匹配

2. **支付詳情**
   - 金額: 20.00 EUR
   - 狀態: succeeded
   - 客戶資訊: 張三
   - 描述: KTV 測試支付 - Morning 時段

3. **測試數據**
   - 確認這是測試環境 (Test mode)
   - 檢查支付方式詳情

### 🎉 成功標誌

如果測試成功，您應該看到：

1. ✅ 應用中顯示 "支付確認成功！"
2. ✅ Stripe Dashboard 中出現新的支付記錄
3. ✅ 支付狀態為 `succeeded`
4. ✅ 金額正確顯示為 20.00 EUR

### 🔗 有用連結

- **Stripe Dashboard**: https://dashboard.stripe.com/test/payments
- **Stripe 測試文檔**: https://stripe.com/docs/testing
- **Stripe API 文檔**: https://stripe.com/docs/api

### 💡 提示

- 測試環境不會真的收錢
- 所有測試支付都是模擬的
- 可以在 Stripe Dashboard 中查看詳細的支付流程
- 測試完成後，可以在 Dashboard 中刪除測試數據
