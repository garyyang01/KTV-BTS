# Bundle API格式更新總結

## ✅ 已完成的修改

### 1. 簡化ParticipantInfo模型
只保留必要的欄位：
- ✅ `email` (電子郵件)
- ✅ `firstName` (名字)
- ✅ `lastName` (姓氏)
- ✅ `passportNumber` (護照號碼)

### 2. 簡化Bundle預訂表單
只保留必要的輸入欄位：
- ✅ Email (電子郵件輸入框)
- ✅ First Name (名字輸入框)
- ✅ Last Name (姓氏輸入框)
- ✅ Passport Number (護照號碼輸入框)

### 3. 更新API請求格式
按照您提供的API規範修改了Bundle請求格式：

```json
{
  "PaymentRefno": "pi_xxx",
  "RecipientEmail": "user@example.com",
  "Ip": "127.0.0.1",
  "TicketInfo": [
    {
      "Id": "tickettrip_xxxxxxxxxxxxxxxx",
      "FamilyName": "Hung",
      "GivenName": "GUO LIN", 
      "IsAdult": true,
      "Session": "Bundle Tour",
      "ArrivalTime": "2025-09-18",
      "Prize": 232.0,
      "Type": "Bundle",
      "EntranceName": "",
      "BundleName": "Rome Independent Tour from Venice by High-Speed Train",
      "From": "",
      "To": "Venice",
      "Phone": "",
      "PassportNumber": "EA123456789",
      "BirthDate": "",
      "Gender": ""
    }
  ]
}
```

### 4. 添加ID生成器
- ✅ 實現了`_generateTicketId()`函數
- ✅ 格式：`tickettrip_` + 16位隨機字符

### 5. 使用預設值
對於不需要的欄位使用空字串：
- ✅ `Phone`: "" (空字串)
- ✅ `BirthDate`: "" (空字串)
- ✅ `Gender`: "" (空字串)
- ✅ `From`: "" (空字串)
- ✅ `EntranceName`: "" (空字串)

## 📋 最終的Bundle預訂流程

1. **選擇Bundle**: 用戶在Bundle頁面選擇想要的Bundle
2. **填寫基本資訊**: 
   - 選擇參與者數量
   - 選擇日期
   - 填寫每個參與者的基本資訊 (Email, 姓名, 護照號碼)
3. **付款**: 跳轉到付款頁面，總價 = Bundle價格 × 參與者數量
4. **API呼叫**: 付款成功後呼叫 `https://ezzn8n.zeabur.app/webhook/order-ticket`

## 🎯 簡化後的優勢

- ✅ 表單更簡潔，用戶體驗更好
- ✅ 減少必填欄位，降低預訂門檻
- ✅ API請求格式符合規範
- ✅ 保持所有必要功能

## 🧪 測試建議

1. **測試表單驗證**:
   - 確認所有必要欄位都有正確的驗證
   - 測試多參與者表單

2. **測試API請求**:
   - 檢查控制台日誌確認請求格式正確
   - 驗證所有欄位都有正確的值

3. **測試完整流程**:
   - 測試Bundle選擇 → 預訂 → 付款 → API呼叫的完整流程
   - 確認付款成功後不會跳出火車票購買對話框

Bundle預訂流程現在已經簡化完成，只收集必要的資訊！
