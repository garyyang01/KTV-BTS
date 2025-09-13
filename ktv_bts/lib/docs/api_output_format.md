# Stripe Payment Service API Output Format

## 📋 接口輸出格式說明 (API Output Format Documentation)

### PaymentResponse 輸出格式

我們的 Stripe 支付服務接口會返回 `PaymentResponse` 物件，包含以下欄位：

#### 成功響應 (Success Response)

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

#### 失敗響應 (Failure Response)

```json
{
  "success": false,
  "payment_intent_id": null,
  "client_secret": null,
  "status": null,
  "amount": null,
  "currency": null,
  "error_message": "Invalid API key provided"
}
```

## 📊 欄位詳細說明 (Field Details)

| 欄位名稱 | 類型 | 必填 | 說明 |
|---------|------|------|------|
| `success` | `bool` | ✅ | 操作是否成功 |
| `payment_intent_id` | `String?` | ❌ | Stripe 支付意圖 ID |
| `client_secret` | `String?` | ❌ | 客戶端密鑰，用於前端支付確認 |
| `status` | `String?` | ❌ | 支付狀態 |
| `amount` | `double?` | ❌ | 支付金額 (歐元) |
| `currency` | `String?` | ❌ | 貨幣代碼 (固定為 "EUR") |
| `error_message` | `String?` | ❌ | 錯誤訊息 (僅在失敗時) |

## 🔄 支付狀態說明 (Payment Status)

| 狀態 | 說明 |
|------|------|
| `requires_payment_method` | 需要支付方式 |
| `requires_confirmation` | 需要確認支付 |
| `requires_action` | 需要額外操作 |
| `processing` | 處理中 |
| `succeeded` | 支付成功 |
| `canceled` | 支付已取消 |

## 💰 金額計算規則 (Amount Calculation)

- **成人 (IsAdult = true)**: 固定 20 歐元
- **兒童 (IsAdult = false)**: 固定 0 歐元 (免費)

## 📝 使用範例 (Usage Examples)

### 1. 創建支付意圖 (Create Payment Intent)

**輸入:**
```dart
PaymentRequest(
  customerName: "張三",
  isAdult: true,
  time: "Morning",
  currency: "EUR"
)
```

**輸出:**
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

### 2. 確認支付 (Confirm Payment)

**輸入:**
```dart
paymentService.confirmPayment(
  paymentIntentId: "pi_test_123456789",
  paymentMethodId: "pm_card_visa"
)
```

**輸出:**
```json
{
  "success": true,
  "payment_intent_id": "pi_test_123456789",
  "client_secret": "pi_test_123456789_secret_abc123",
  "status": "succeeded",
  "amount": 20.0,
  "currency": "EUR",
  "error_message": null
}
```

### 3. 查詢支付狀態 (Get Payment Status)

**輸入:**
```dart
paymentService.getPaymentStatus("pi_test_123456789")
```

**輸出:**
```json
{
  "success": true,
  "payment_intent_id": "pi_test_123456789",
  "client_secret": "pi_test_123456789_secret_abc123",
  "status": "succeeded",
  "amount": 20.0,
  "currency": "EUR",
  "error_message": null
}
```

### 4. 取消支付 (Cancel Payment)

**輸入:**
```dart
paymentService.cancelPayment("pi_test_123456789")
```

**輸出:**
```json
{
  "success": true,
  "payment_intent_id": "pi_test_123456789",
  "client_secret": "pi_test_123456789_secret_abc123",
  "status": "canceled",
  "amount": 20.0,
  "currency": "EUR",
  "error_message": null
}
```

## ❌ 錯誤處理 (Error Handling)

### 常見錯誤類型

1. **API 金鑰錯誤**
```json
{
  "success": false,
  "error_message": "Invalid API key provided"
}
```

2. **網絡錯誤**
```json
{
  "success": false,
  "error_message": "Network error: Connection timeout"
}
```

3. **支付失敗**
```json
{
  "success": false,
  "error_message": "Your card was declined."
}
```

4. **支付意圖不存在**
```json
{
  "success": false,
  "error_message": "No such payment_intent: pi_invalid_id"
}
```

## 🔧 前端整合 (Frontend Integration)

### 使用 client_secret 進行前端支付

```javascript
// 使用 Stripe.js 進行前端支付
const stripe = Stripe('pk_test_your_public_key');
const {error} = await stripe.confirmCardPayment(clientSecret, {
  payment_method: {
    card: cardElement,
    billing_details: {
      name: 'Customer Name'
    }
  }
});
```

## 📱 實際使用流程 (Real Usage Flow)

1. **創建支付意圖** → 獲得 `client_secret`
2. **前端收集支付方式** → 使用 Stripe Elements
3. **確認支付** → 調用 `confirmPayment`
4. **處理結果** → 根據 `status` 處理成功/失敗

## 🛡️ 安全性注意事項 (Security Notes)

- `client_secret` 僅用於前端支付確認
- 不要在日誌中記錄敏感資訊
- 使用 HTTPS 傳輸所有支付相關數據
- 定期輪換 API 金鑰
