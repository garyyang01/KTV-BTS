# 新天鵝堡票務系統 Landing Page 開發步驟

## 專案概述
基於 CLAUDE.md 的專案現況，這是一個 Flutter 票務應用程式，專門為新天鵝堡（Neuschwanstein Castle）售票設計。本次開發範圍限縮在 **App 頁面實作**，實作一個使用者輸入基本資訊的頁面並整合現有支付 API。

## 重要說明
- **開發範圍**：僅限 App 頁面實作，不包含後端開發
- **前端顯示語言**：目前所有前端顯示文字都使用英文
- **票價資訊**：成人票價 19 EUR，18歲以下免費

## 後端 API 規格
```json
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
```

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
- [ ] 建立模型類別：
  - `lib/models/ticket_info.dart` - 對應後端 API 規格的票券資訊模型
- [ ] 建立服務類別：
  - `lib/services/ticket_service.dart` - 處理票券相關 API 呼叫

### 階段二：票務預訂頁面 UI 實作

#### 步驟 2.1：頁面基本結構
- [ ] 實作主標題：「Visit Neuschwanstein Castle – Your Fairytale Awaits」
- [ ] 實作副標題：「Skip the lines and secure your spot at Germany's most magical castle.」
- [ ] 整合城堡全景圖片（從 Marienbrücke 角度）
- [ ] 添加信任標誌：★★★★★ 評分、官方票券、安全支付標章

#### 步驟 2.2：票券資訊表單（對應後端 API）
- [ ] 實作 FamilyName 輸入欄位
- [ ] 實作 GivenName 輸入欄位
- [ ] 實作 IsAdult 選擇（Adult / Under 18）
- [ ] 實作 ArrivalTime 日期選擇器（YYYY-MM-DD 格式）
- [ ] 實作 Session 時間段選擇（Morning / Afternoon）
- [ ] 實作 Prize 價格顯示邏輯（成人 19 EUR / 18歲以下 0 EUR）
- [ ] 實作表單驗證邏輯
- [ ] 實作 "Book Now" 按鈕與載入狀態


### 階段三：資料處理與 API 整合

#### 步驟 3.1：票券資料模型實作
- [ ] 建立 TicketInfo 模型類別（對應後端 API 規格）
- [ ] 實作資料驗證邏輯
- [ ] 實作 JSON 序列化/反序列化

#### 步驟 3.2：表單資料處理
- [ ] 實作表單資料收集邏輯
- [ ] 實作 IsAdult 布林值轉換（Adult = true, Under 18 = false）
- [ ] 實作 Prize 計算邏輯（成人 19, 未成年 0）
- [ ] 實作 ArrivalTime 日期格式化（YYYY-MM-DD）

### 階段四：支付整合

#### 步驟 4.1：整合現有 Stripe 支付服務
- [ ] 連接現有的 Stripe 支付服務
- [ ] 將票券資料傳遞給支付流程
- [ ] 實作支付成功後的確認頁面
- [ ] 實作支付失敗的錯誤處理

## 今日目標
建立一個票務預訂 App 頁面，包含：
1. FamilyName & GivenName 輸入欄位
2. IsAdult 選擇（Adult / Under 18）
3. ArrivalTime 日期選擇器（YYYY-MM-DD）
4. Session 時間段選擇（Morning / Afternoon）
5. Prize 動態價格顯示（成人 19 EUR / 18歲以下 0 EUR）
6. 表單驗證與資料處理
7. 整合現有 Stripe 支付 API
8. 所有文字顯示使用英文
9. 符合後端 API 規格的資料格式

## 預估時程
- 階段一：1 天（專案設置）
- 階段二：1-2 天（UI 實作）
- 階段三：1 天（資料處理）
- 階段四：1 天（支付整合）

總計：4-5 天的 App 開發時間

## 備註
此步驟分解專注於 App 頁面實作，基於提供的後端 API 規格。所有欄位都對應到後端 TicketInfo 資料結構，確保前後端資料格式一致性。
