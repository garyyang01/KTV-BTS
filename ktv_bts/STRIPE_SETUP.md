# Stripe API 設定說明

## 問題解決

你遇到的錯誤是因為缺少 Stripe API 金鑰設定。

## 解決步驟

### 1. 創建 .env 檔案

在專案根目錄 (`/Users/jasonhung/Works/Jason/KTV-BTS/ktv_bts/`) 創建一個 `.env` 檔案：

```bash
# Stripe API Configuration
STRIPE_PUBLIC_KEY=pk_test_your_actual_public_key_here
STRIPE_SECRET_KEY=sk_test_your_actual_secret_key_here
ENVIRONMENT=development
```

### 2. 獲取 Stripe API 金鑰

1. 前往 [Stripe Dashboard](https://dashboard.stripe.com/)
2. 登入你的帳戶
3. 進入 **Developers** > **API keys**
4. 複製 **Publishable key** (pk_test_...) 和 **Secret key** (sk_test_...)

### 3. 更新 .env 檔案

將複製的金鑰貼到 `.env` 檔案中：

```
STRIPE_PUBLIC_KEY=pk_test_51AbC123...
STRIPE_SECRET_KEY=sk_test_51XyZ789...
ENVIRONMENT=development
```

### 4. 重新運行應用程式

```bash
flutter run
```

## 注意事項

- 確保使用測試環境的金鑰 (以 `pk_test_` 和 `sk_test_` 開頭)
- 不要將 `.env` 檔案提交到版本控制系統
- 生產環境請使用不同的金鑰

## 測試

設定完成後，點擊「創建支付意圖」按鈕應該可以成功連接到 Stripe API。
