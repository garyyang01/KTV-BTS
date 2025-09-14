# 新天鵝堡票務系統 - 火車票整合功能開發步驟

## 專案概述
基於現有的新天鵝堡票務系統，新增火車票選購功能。使用者在購買城堡門票後，可以選擇是否購買相關的火車票，提供完整的旅遊體驗。

## 重要說明
- **開發範圍**：僅限 App 頁面實作，不包含後端開發
- **前端顯示語言**：所有前端顯示文字使用英文
- **整合方式**：在現有購票流程中插入火車票選購步驟

## 🚂 新功能需求分析

### 核心流程設計
```
使用者填寫城堡門票資訊 
    ↓
點擊「購買門票」按鈕
    ↓
觸發火車票搜尋（後端 API，暫不實作）
    ↓
彈出火車票選購頁面 (Pop-up)
    ↓
使用者選擇火車票或跳過
    ↓
轉到信用卡支付頁面（已實作）
```

### 火車票資訊結構
```json
{
  "TrainTickets": [
    {
      "OriginStation": "string",      // 起始站
      "DestinationStation": "string", // 終點站
      "TrainName": "string",          // 名稱(車種)
      "Price": 15.50,                 // 票價 (EUR)
      "DepartureTime": "09:30",       // 出發時間
      "ArrivalTime": "11:45",         // 到達時間
      "Duration": "2h 15m",           // 行程時間
      "TrainType": "Regional Express", // 車種類型
      "TicketId": "train_001"         // 票券ID
    }
  ],
  "OrderSummary": {
    "CastleTicketsTotal": 20.00,      // 城堡門票總價
    "SelectedTrainTicket": 15.50,     // 選中的火車票價格 (可為 0)
    "TotalAmount": 35.50              // 總金額
  }
}
```

## 📊 目前進度狀態
**火車票功能進度：35% 完成**

### ✅ 已完成階段：
- **階段一：UI 組件設計（部分完成）** - 基礎 UI 組件已建立

### 🔄 進行中階段：
- **階段一：UI 組件設計** - 剩餘操作按鈕待實作

### ⏳ 待開發階段：
- **階段二：資料模型建立** - TrainTicket 模型類別（部分完成）
- **階段三：流程整合** - 與現有購票流程整合
- **階段四：API 準備** - 為未來後端整合做準備

## 開發步驟分解

### 階段一：UI 組件設計與實作

#### 步驟 1.1：建立火車票彈出頁面結構 ✅
- [x] 建立 `lib/pages/train_ticket_selection_page.dart`
- [x] 設計 Modal Bottom Sheet 或 Dialog 彈出介面
- [x] 實作頁面基本佈局（標題、內容區域、按鈕區域）
- [x] 添加關閉/返回功能

#### 步驟 1.2：設計火車票卡片組件 ✅
- [x] 建立 `lib/widgets/train_ticket_card.dart`
- [x] 設計票券卡片 UI 包含：
  - 起始站 → 終點站 路線顯示
  - 車種名稱和類型
  - 出發/到達時間
  - 行程時間
  - 票價顯示
- [x] 實作選擇狀態視覺回饋
- [x] 添加卡片點擊選擇功能

#### 步驟 1.3：實作火車票列表組件 ✅
- [x] 建立 `lib/widgets/train_ticket_list.dart`
- [x] 實作多張火車票的列表顯示
- [x] 添加單選功能（一次只能選一張火車票）
- [x] 實作空狀態顯示（無可用火車票時）
- [x] 添加載入狀態指示器

#### 步驟 1.4：設計總金額顯示區域 ✅
- [x] 建立 `lib/widgets/order_summary_widget.dart`
- [x] 實作訂單摘要顯示包含：
  - 城堡門票總價
  - 選中的火車票價格（如有）
  - 總金額計算和顯示
- [x] 實作動態價格更新（當選擇不同火車票時）
- [x] 添加價格格式化（歐元符號、小數點）

#### 步驟 1.5：設計頁面操作按鈕
- [ ] 實作「選擇此火車票」按鈕
- [ ] 實作「跳過火車票」按鈕
- [ ] 添加按鈕狀態管理（選中/未選中）
- [ ] 實作按鈕點擊事件處理

### 階段二：資料模型與狀態管理

#### 步驟 2.1：建立火車票資料模型 ✅
- [x] 建立 `lib/models/train_ticket.dart`
- [x] 定義 TrainTicket 類別包含所有必要欄位
- [x] 實作 JSON 序列化/反序列化方法
- [x] 添加資料驗證邏輯

#### 步驟 2.2：建立火車票搜尋請求模型
- [ ] 建立 `lib/models/train_search_request.dart`
- [ ] 定義搜尋參數（日期、時間、起終點等）
- [ ] 基於城堡門票資訊自動填充搜尋條件
- [ ] 實作請求資料格式化

#### 步驟 2.3：建立火車票選擇狀態管理
- [ ] 建立 `lib/providers/train_ticket_provider.dart`
- [ ] 使用 Provider 管理火車票選擇狀態
- [ ] 實作選擇/取消選擇邏輯
- [ ] 管理載入和錯誤狀態

#### 步驟 2.4：更新總訂單模型
- [ ] 更新 `lib/models/booking_request.dart`
- [ ] 添加火車票資訊到總訂單
- [ ] 實作總價計算（城堡門票 + 火車票）
- [ ] 添加價格明細結構（分別記錄門票和火車票價格）
- [ ] 更新支付流程資料結構

### 階段三：流程整合與導航

#### 步驟 3.1：修改現有購票按鈕邏輯
- [ ] 更新 `lib/widgets/booking_form.dart` 中的提交邏輯
- [ ] 將原本直接跳轉支付改為觸發火車票搜尋
- [ ] 實作火車票搜尋觸發機制
- [ ] 添加載入狀態顯示

#### 步驟 3.2：實作火車票頁面彈出邏輯
- [ ] 在購票按鈕點擊後顯示火車票選擇頁面
- [ ] 實作 Modal 或 Bottom Sheet 彈出動畫
- [ ] 處理彈出頁面的生命週期
- [ ] 實作頁面關閉邏輯

#### 步驟 3.3：整合支付流程
- [ ] 修改支付頁面接收火車票資訊
- [ ] 更新 `lib/pages/payment_page.dart` 顯示總訂單明細
- [ ] 實作城堡門票 + 火車票的總價計算
- [ ] 確保支付成功後包含所有票券資訊

#### 步驟 3.4：實作導航流程
- [ ] 火車票選擇完成後導航到支付頁面
- [ ] 跳過火車票時直接導航到支付頁面
- [ ] 實作返回邏輯和狀態保持
- [ ] 處理導航過程中的錯誤情況

### 階段四：API 整合準備（未來實作）

#### 步驟 4.1：建立火車票服務介面
- [ ] 建立 `lib/services/train_ticket_service.dart`
- [ ] 定義火車票搜尋 API 介面
- [ ] 實作模擬資料提供者（用於開發測試）
- [ ] 準備真實 API 整合的架構

#### 步驟 4.2：實作火車票搜尋邏輯
- [ ] 基於城堡門票的日期和時間搜尋火車票
- [ ] 實作搜尋結果快取機制
- [ ] 處理搜尋失敗和無結果情況
- [ ] 實作重試機制

#### 步驟 4.3：錯誤處理與用戶體驗
- [ ] 實作網路錯誤處理
- [ ] 添加搜尋超時處理
- [ ] 實作用戶友好的錯誤訊息
- [ ] 添加重試和刷新功能

## 🎨 UI/UX 設計規範

### 火車票卡片設計
```
┌─────────────────────────────────────┐
│ 🚂 Regional Express                 │
│                                     │
│ Munich Hbf ────────→ Füssen        │
│ 09:30              11:45            │
│                                     │
│ Duration: 2h 15m    Price: €15.50   │
│                                     │
│ [ Select This Ticket ]              │
└─────────────────────────────────────┘
```

### 彈出頁面佈局
```
┌─────────────────────────────────────┐
│ ✕                Train Tickets      │
├─────────────────────────────────────┤
│                                     │
│ Available trains for your trip:     │
│                                     │
│ [Train Ticket Card 1]               │
│ [Train Ticket Card 2]               │
│ [Train Ticket Card 3]               │
│                                     │
├─────────────────────────────────────┤
│ Order Summary:                      │
│ Castle Tickets: €20.00              │
│ Train Ticket: €15.50 (if selected)  │
│ ─────────────────────               │
│ Total: €35.50                       │
├─────────────────────────────────────┤
│ [ Continue with Selected ] [ Skip ] │
└─────────────────────────────────────┘
```

## 📱 響應式設計考量

### 手機版 (Mobile)
- 使用 Bottom Sheet 彈出方式
- 火車票卡片垂直排列
- 按鈕全寬度顯示

### 平板版 (Tablet)
- 使用 Dialog 彈出方式
- 火車票卡片可以 2 列顯示
- 按鈕水平排列

### 網頁版 (Web)
- 使用 Modal Dialog
- 火車票卡片網格佈局
- 滑鼠懸停效果

## 🔄 狀態管理架構

### TrainTicketProvider 狀態
```dart
class TrainTicketProvider extends ChangeNotifier {
  List<TrainTicket> availableTickets = [];
  TrainTicket? selectedTicket;
  bool isLoading = false;
  String? errorMessage;
  double castleTicketsTotal = 0.0;  // 城堡門票總價
  
  // 搜尋火車票
  Future<void> searchTrainTickets(BookingRequest bookingInfo);
  
  // 選擇火車票
  void selectTicket(TrainTicket ticket);
  
  // 清除選擇
  void clearSelection();
  
  // 跳過火車票
  void skipTrainTicket();
  
  // 計算總金額
  double get totalAmount {
    double trainTicketPrice = selectedTicket?.price ?? 0.0;
    return castleTicketsTotal + trainTicketPrice;
  }
  
  // 設置城堡門票總價
  void setCastleTicketsTotal(double total) {
    castleTicketsTotal = total;
    notifyListeners();
  }
}
```

## 🧪 測試資料

### 模擬火車票資料
```json
[
  {
    "OriginStation": "Munich Hbf",
    "DestinationStation": "Füssen",
    "TrainName": "Regional Express",
    "Price": 15.50,
    "DepartureTime": "09:30",
    "ArrivalTime": "11:45",
    "Duration": "2h 15m",
    "TrainType": "RE",
    "TicketId": "train_001"
  },
  {
    "OriginStation": "Munich Hbf",
    "DestinationStation": "Füssen",
    "TrainName": "Regional",
    "Price": 12.80,
    "DepartureTime": "10:15",
    "ArrivalTime": "12:30",
    "Duration": "2h 15m",
    "TrainType": "R",
    "TicketId": "train_002"
  },
  {
    "OriginStation": "Munich Hbf",
    "DestinationStation": "Füssen",
    "TrainName": "InterCity Express",
    "Price": 28.90,
    "DepartureTime": "11:00",
    "ArrivalTime": "12:45",
    "Duration": "1h 45m",
    "TrainType": "ICE",
    "TicketId": "train_003"
  }
]
```

## 📋 開發優先順序

### 第一階段：基礎 UI（1-2 天）✅ 80% 完成
1. ✅ 建立火車票彈出頁面
2. ✅ 設計火車票卡片組件
3. ✅ 實作訂單摘要和總金額顯示
4. ⏳ 實作基本的選擇邏輯（剩餘操作按鈕）

### 第二階段：資料整合（1 天）⏳ 25% 完成
1. ✅ 建立資料模型（TrainTicket 完成）
2. ⏳ 整合狀態管理（待實作 Provider）
3. ⏳ 連接現有購票流程

### 第三階段：流程完善（1 天）
1. 完善導航邏輯
2. 整合支付流程
3. 錯誤處理和用戶體驗優化

### 第四階段：測試與優化（0.5 天）
1. 功能測試
2. UI/UX 調整
3. 效能優化

## 🎯 成功標準

### 功能完整性
- ✅ 使用者可以在購票後看到火車票選項
- ✅ 使用者可以選擇或跳過火車票
- ✅ 火車票選擇頁面顯示包含門票的總金額
- ✅ 總金額隨火車票選擇動態更新
- ✅ 選擇的火車票正確顯示在支付頁面
- ✅ 總價計算包含火車票價格

### 用戶體驗
- ✅ 彈出頁面動畫流暢
- ✅ 火車票資訊清楚易讀
- ✅ 總金額顯示清楚明瞭
- ✅ 價格更新即時反應
- ✅ 選擇操作直觀簡單
- ✅ 錯誤處理用戶友好

### 技術品質
- ✅ 程式碼結構清晰
- ✅ 狀態管理正確
- ✅ 響應式設計適配
- ✅ 效能表現良好

## 📝 備註

### 技術考量
- 使用現有的 Provider 狀態管理模式
- 保持與現有 UI 風格一致
- 確保在不同螢幕尺寸下的良好體驗
- 為未來 API 整合預留擴展空間

### 業務邏輯
- 火車票為可選項目，不影響城堡門票購買
- 支援單選火車票（一次旅程一張票）
- 價格以歐元計算，與城堡門票統一
- 搜尋條件基於城堡門票的日期和時間段

---

**總預估開發時間：3-4 天**
**複雜度：中等**
**依賴項目：現有的城堡門票系統和支付流程**
