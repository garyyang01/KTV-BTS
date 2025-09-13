# 新天鵝堡票務系統 Landing Page 開發步驟

## 專案概述
基於 CLAUDE.md 的專案現況，這是一個 Flutter 票務應用程式，專門為新天鵝堡（Neuschwanstein Castle）售票設計。本次開發範圍限縮在 **App 頁面實作**，實作一個使用者輸入基本資訊的頁面並整合現有支付 API。

## 重要說明
- **開發範圍**：僅限 App 頁面實作，不包含後端開發
- **前端顯示語言**：目前所有前端顯示文字都使用英文
- **票價資訊**：成人票價 19 EUR，18歲以下免費

## 後端 API 規格
```json
{
  "PaymentRefno": "string",
  "RecipientEmail": "string",
  "TotalTickets": 1,
  "TicketInfo": [
    {
      "FamilyName": "string",
      "GivenName": "string",
      "IsAdult": true,
      "Session": "Morning | Afternoon",
      "ArrivalTime": "YYYY-MM-DD",
      "Prize": 19
    }
  ]
}
```

**說明**：
- `PaymentRefno`: 支付參考號碼（初期可為空值，由後續支付 API 處理）
- `RecipientEmail`: 收件人電子郵件（一個 Email 可包含多個票券）
- `TotalTickets`: 票券總數
- `TicketInfo`: 票券資訊陣列（可包含多個票券）

## 開發步驟分解

### 階段一：專案基礎設置

#### 步驟 1.1：環境配置與依賴管理
- [ ] 檢查並更新 `pubspec.yaml` 中的依賴套件
- [ ] 添加必要的 UI 套件（如 intl 用於日期格式化）
- [ ] 設置狀態管理解決方案（Provider/Riverpod/Bloc）
- [ ] 確認現有 Stripe 支付相關依賴
- [ ] 檢查環境變數管理（.env 檔案）

#### 步驟 1.2：專案結構設置
- [ ] 建立頁面結構：
  - `lib/pages/ticket_booking_page.dart` - 主要票務預訂頁面
  - `lib/pages/payment_confirmation_page.dart` - 支付確認頁面
- [ ] 建立 UI 組件：
  - `lib/widgets/booking_form.dart` - 預訂表單組件
  - `lib/widgets/price_display.dart` - 價格顯示組件
  - `lib/widgets/email_input.dart` - 電子郵件輸入組件
- [ ] 建立模型類別（後續階段）：
  - `lib/models/booking_request.dart` - 完整預訂請求模型
  - `lib/models/ticket_info.dart` - 票券資訊模型
- [ ] 建立服務類別（後續階段）：
  - `lib/services/ticket_service.dart` - 處理票券相關 API 呼叫

### 階段二：票務預訂頁面 UI 實作

#### 步驟 2.1：頁面基本結構
- [ ] 實作主標題：「Visit Neuschwanstein Castle – Your Fairytale Awaits」
- [ ] 實作副標題：「Skip the lines and secure your spot at Germany's most magical castle.」
- [ ] 整合城堡全景圖片（從 Marienbrücke 角度）
- [ ] 添加信任標誌：★★★★★ 評分、官方票券、安全支付標章

#### 步驟 2.2：預訂表單 UI 介面（對應後端 API）
- [ ] 實作 RecipientEmail 電子郵件輸入欄位
- [ ] 實作 FamilyName 輸入欄位
- [ ] 實作 GivenName 輸入欄位
- [ ] 實作 IsAdult 選擇（Adult / Under 18）
- [ ] 實作 ArrivalTime 日期選擇器（YYYY-MM-DD 格式）
- [ ] 實作 Session 時間段選擇（Morning / Afternoon）
- [ ] 實作 Prize 價格顯示邏輯（成人 19 EUR / 18歲以下 0 EUR）
- [ ] 實作基本表單驗證（必填欄位、Email 格式等）
- [ ] 實作 "Book Now" 按鈕與載入狀態
- [ ] 實作響應式 UI 設計


### 階段三：資料模型與處理邏輯

#### 步驟 3.1：完整預訂請求模型實作
- [ ] 建立 BookingRequest 模型類別（對應完整後端 API 規格）
- [ ] 建立 TicketInfo 模型類別
- [ ] 實作 JSON 序列化/反序列化
- [ ] 實作資料驗證邏輯

#### 步驟 3.2：表單資料處理與轉換
- [ ] 實作表單資料收集邏輯
- [ ] 實作 PaymentRefno 初始化（空值處理）
- [ ] 實作 TotalTickets 計算邏輯
- [ ] 實作 IsAdult 布林值轉換（Adult = true, Under 18 = false）
- [ ] 實作 Prize 計算邏輯（成人 19, 未成年 0）
- [ ] 實作 ArrivalTime 日期格式化（YYYY-MM-DD）

### 階段四：支付整合

#### 步驟 4.1：整合現有 Stripe 支付服務
- [ ] 連接現有的 Stripe 支付服務
- [ ] 將完整 BookingRequest 資料傳遞給支付流程
- [ ] 實作 PaymentRefno 更新邏輯（支付成功後）
- [ ] 實作支付成功後的確認頁面
- [ ] 實作支付失敗的錯誤處理

## 開發優先順序

### 第一步：UI 介面實作（優先）
建立票務預訂 App 頁面 UI，包含：
1. RecipientEmail 電子郵件輸入欄位
2. FamilyName & GivenName 輸入欄位
3. IsAdult 選擇（Adult / Under 18）
4. ArrivalTime 日期選擇器（YYYY-MM-DD）
5. Session 時間段選擇（Morning / Afternoon）
6. Prize 動態價格顯示（成人 19 EUR / 18歲以下 0 EUR）
7. 基本表單驗證（必填欄位、Email 格式）
8. "Book Now" 按鈕與載入狀態
9. 響應式 UI 設計
10. 所有文字顯示使用英文

### 第二步：資料處理與服務整合（後續）
- TicketInfo 模型與資料處理邏輯
- 完整 BookingRequest 資料結構
- Stripe 支付 API 整合

## 預估時程
- 階段一：1 天（專案設置）
- 階段二：1-2 天（UI 實作）
- 階段三：1 天（資料處理）
- 階段四：1 天（支付整合）

總計：4-5 天的 App 開發時間

## 備註
此步驟分解專注於 App 頁面實作，基於提供的完整後端 API 規格。開發採用分階段方式：
1. **優先實作 UI 介面**：完成所有表單欄位的視覺呈現和基本驗證
2. **後續處理資料邏輯**：實作 TicketInfo 模型和 Service 層
3. **最後整合支付**：連接 Stripe API 並處理 PaymentRefno

資料結構說明：
- 一個 Email 可以包含多個票券資訊
- PaymentRefno 初期為空值，由支付 API 後續處理
- 所有欄位都對應到後端 BookingRequest 資料結構
