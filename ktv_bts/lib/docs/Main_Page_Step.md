# 主頁面開發步驟 - Main Page Implementation

## 專案概述
實作一個統一的主頁面，整合車站票券和景點門票的搜索與申請功能。使用者可以通過搜索框選擇目標地點，系統會動態顯示對應的票券申請區塊。

## 重要說明
- **開發範圍**：僅限 App 頁面實作，不包含後端開發
- **前端顯示語言**：所有前端顯示文字使用英文
- **整合方式**：替換現有的 `TicketBookingPage` 作為應用程式首頁
- **設計優先**：以手機版設計為主，搜索框在上方，票券申請在下方

## 🎯 功能需求分析

### 核心流程設計
```
使用者進入主頁面
    ↓
選擇搜索目標 (車站/景點)
    ↓
點擊搜索按鈕
    ↓
系統動態顯示對應的票券申請區塊
    ↓
使用者填寫申請表單
    ↓
提交申請 → 進入支付流程
```

### 搜索選項配置（Hard Code + 多語言關鍵字）
```json
{
  "searchOptions": [
    {
      "id": "munich_central",
      "name": "Munich Central",
      "type": "station",
      "description": "Munich Central Railway Station",
      "stationCode": "ST_L6NN3P6K",
      "services": ["rail_booking", "train_search"],
      "keywords": ["Munich","München","Munich Hbf","München Hauptbahnhof","Munich Central","Munich Main Station","慕尼黑","慕尼黑中央車站"]
    },
    {
      "id": "neuschwanstein_castle", 
      "name": "Neuschwanstein Castle",
      "type": "attraction",
      "description": "Fairy-tale Castle in Bavaria",
      "ticketTypes": ["adult", "under18"],
      "services": ["attraction_booking", "castle_tickets"],
      "keywords": ["新天鵝堡","新天鹅堡","Neuschwanstein","Neuschwanstein Castle","Schloss Neuschwanstein","노이슈반슈타인성","Château de Neuschwanstein"]
    },
    {
      "id": "fuessen_station",
      "name": "Füssen Station",
      "type": "station", 
      "description": "Füssen Railway Station",
      "stationCode": "ST_FUESSEN",
      "services": ["rail_booking", "train_search"],
      "keywords": ["Füssen","Fussen","福森","Bahnhof Füssen"]
    },
    {
      "id": "uffizi_gallery",
      "name": "Uffizi Gallery",
      "type": "attraction",
      "description": "World-famous Renaissance art museum in Florence",
      "ticketTypes": ["adult", "under18"],
      "services": ["attraction_booking", "museum_tickets"],
      "keywords": ["烏菲齊美術館","烏菲茲美術館","Uffizi","Uffizi Gallery","Galleria degli Uffizi","Galerie des Offices","Галерея Уффици"]
    },
    {
      "id": "florence_station",
      "name": "Florence SMN",
      "type": "station",
      "description": "Firenze Santa Maria Novella Railway Station", 
      "stationCode": "ST_DKRRM9Q4",
      "services": ["rail_booking", "train_search"],
      "keywords": ["Florence","Firenze","Florenz","佛羅倫斯","Firenze S. M. Novella","Firenze SMN","Florence SMN","Firenze Centrale","佛羅倫斯中央車站"]
    },
    {
      "id": "milan_station",
      "name": "Milano Centrale",
      "type": "station",
      "description": "Milan Central Railway Station",
      "stationCode": "ST_L6NN3P6K",
      "services": ["rail_booking", "train_search"],
      "keywords": ["Milan","Milano","Milano Centrale","米蘭","米蘭中央車站"]
    },
  ]
}
```

### 現有系統整合
- **車站票券**：整合現有的 `RailBookingService` 和火車票搜索功能
- **景點門票**：整合現有的 `BookingForm` 和新天鵝堡票券申請系統
- **支付流程**：使用現有的 `PaymentRequest` 和支付頁面

## 📊 目前進度狀態
**主頁面功能進度：25% 完成**

### ✅ 已完成階段：
- **階段一：UI 組件設計** - 🔄 進行中 (主頁面佈局和搜索組件)

### ⏳ 待開發階段：
- **階段二：動態內容管理** - 根據選擇顯示不同申請區塊
- **階段三：表單整合** - 整合現有的票券申請表單
- **階段四：導航優化** - 完善頁面間的導航流程

## 🚀 最新進度報告

### ✅ 已完成的核心功能
1. **主頁面架構** - 完整的響應式設計和佈局
2. **多語言搜索系統** - 支援 6 種語言關鍵字搜索
3. **搜索組件** - 可輸入的下拉選單，即時篩選功能
4. **基礎導航** - 主頁面路由配置完成

### 🔄 目前實作狀態
- **搜索功能**: 100% 完成 - 支援即時搜索、多語言關鍵字匹配
- **UI 組件**: 75% 完成 - 主頁面和搜索組件已實作
- **內容顯示**: 25% 完成 - 基礎佔位符完成，待實作動態切換
- **導航系統**: 50% 完成 - 基本路由完成，待完善頁面間導航

### 📱 已實作的檔案
```
lib/
├── pages/
│   └── main_page.dart ✅
├── widgets/
│   └── search_bar_widget.dart ✅
└── main.dart ✅ (路由更新)
```

### 🎯 下一步重點任務
1. **完善內容顯示區域** - 實作 content_display_widget.dart
2. **建立搜索選項模型** - 重構為獨立的 search_option.dart
3. **動態內容切換** - 根據選擇顯示不同申請區塊
4. **狀態管理** - 實作 Provider 架構

## 🧪 已實作功能測試

### ✅ 多語言搜索測試（已驗證）
用戶現在可以使用以下關鍵字進行搜索：

| 輸入關鍵字 | 搜索結果 | 語言 | 狀態 |
|-----------|---------|------|------|
| "慕尼黑" | Munich Central | 中文 | ✅ 已實作 |
| "新天鵝堡" | Neuschwanstein Castle | 中文 | ✅ 已實作 |
| "Uffizi" | Uffizi Gallery | 英文 | ✅ 已實作 |
| "佛羅倫斯" | Florence SMN | 中文 | ✅ 已實作 |
| "Milano" | Milano Centrale | 義大利文 | ✅ 已實作 |
| "München" | Munich Central | 德文 | ✅ 已實作 |
| "노이슈반슈타인성" | Neuschwanstein Castle | 韓文 | ✅ 已實作 |

### ✅ UI 功能測試（已驗證）
- **即時搜索**: ✅ 輸入時立即篩選結果
- **下拉選單**: ✅ 點擊輸入框顯示所有選項
- **選項選擇**: ✅ 點擊選項自動填入並關閉下拉
- **清除功能**: ✅ 選擇後顯示清除按鈕
- **搜索按鈕**: ✅ 只在選擇選項後啟用
- **動態內容**: ✅ 內容區域根據選擇更新顯示

## 開發步驟分解

### 階段一：UI 組件設計與實作

#### 步驟 1.1：建立主頁面結構 ✅
- [x] 建立 `lib/pages/main_page.dart`
- [x] 設計頁面基本佈局（搜索區域、內容區域）
- [x] 實作響應式設計架構
- [x] 添加頁面標題和基本樣式

#### 步驟 1.2：實作搜索組件 ✅
- [x] 建立 `lib/widgets/search_bar_widget.dart`
- [x] 實作可輸入的下拉選單 (Autocomplete/ComboBox) 包含：
  - Munich Central (車站選項)
  - Neuschwanstein Castle (景點選項)
  - Füssen Station (車站選項)
  - Uffizi Gallery (景點選項)
  - Florence SMN (車站選項)
  - Milano Centrale (車站選項)
- [x] 實作多語言關鍵字搜索功能
- [x] 支援用戶輸入和即時篩選功能
- [x] 添加搜索按鈕和點擊事件
- [x] 實作選擇狀態管理和輸入驗證

#### 步驟 1.3：設計內容顯示區域
- [ ] 建立 `lib/widgets/content_display_widget.dart`
- [ ] 實作動態內容切換邏輯
- [ ] 設計載入狀態和空狀態顯示
- [ ] 添加內容區域的動畫效果

#### 步驟 1.4：建立搜索選項模型
- [ ] 建立 `lib/models/search_option.dart`
- [ ] 定義搜索選項的資料結構包含：
  - 基本資訊（id, name, type, description）
  - 多語言關鍵字陣列 (keywords)
  - 服務類型和站點代碼
- [ ] 實作關鍵字搜索邏輯
- [ ] 實作選項類型判斷邏輯
- [ ] 添加多語言搜索配置管理

### 階段二：動態內容管理

#### 步驟 2.1：實作車站票券區塊
- [ ] 建立 `lib/widgets/station_ticket_widget.dart`
- [ ] 整合現有的 `RailBookingService` 火車票搜索功能
- [ ] 設計火車票申請表單包含：
  - 出發站：Munich Central (固定)
  - 目的地選擇（下拉選單）
  - 出發日期和時間選擇
  - 乘客數量（成人/兒童）
  - 票種和價格顯示
- [ ] 整合現有的 `TrainSolution` 和 `TrainStation` 模型
- [ ] 實作表單驗證和火車班次搜索邏輯

#### 步驟 2.2：實作景點門票區塊
- [ ] 建立 `lib/widgets/attraction_ticket_widget.dart`
- [ ] 整合現有的 `BookingForm` 新天鵝堡票券申請表單
- [ ] 使用現有的票券申請功能包含：
  - 多張票券預訂（現有功能）
  - 姓名輸入（FamilyName, GivenName）
  - 年齡選擇（Adult 19 EUR, Under 18 1 EUR）
  - 時間段選擇（Morning/Afternoon）
  - 日期選擇和電子郵件輸入
- [ ] 整合現有的 `PriceDisplay` 價格計算組件
- [ ] 調整表單樣式以配合主頁面設計

#### 步驟 2.3：建立內容路由管理
- [ ] 建立 `lib/providers/main_page_provider.dart`
- [ ] 使用 Provider 管理頁面狀態
- [ ] 實作搜索選擇和內容切換邏輯
- [ ] 管理表單資料和驗證狀態

#### 步驟 2.4：實作搜索結果顯示
- [ ] 設計搜索結果的展示方式
- [ ] 實作選項詳細資訊顯示
- [ ] 添加選項圖片和描述
- [ ] 實作搜索歷史記錄

### 階段三：表單整合與導航

#### 步驟 3.1：整合現有票券表單
- [ ] 重構現有的 `BookingForm` 組件以支援主頁面
- [ ] 適配車站票券（火車票）和景點門票（城堡票）的不同需求
- [ ] 統一表單驗證和提交邏輯
- [ ] 整合現有的 `TicketInfo` 和 `PaymentRequest` 模型
- [ ] 實作表單資料的統一管理

#### 步驟 3.2：實作支付流程整合
- [ ] 修改支付頁面以支援不同票券類型
- [ ] 更新 `PaymentRequest` 模型
- [ ] 實作車站票券的支付邏輯
- [ ] 確保景點門票支付流程正常

#### 步驟 3.3：完善導航邏輯 🔄
- [x] 更新 `main.dart` 的路由配置
- [x] 替換 `TicketBookingPage` 為新的 `MainPage` 作為首頁
- [x] 保留現有的支付頁面和確認頁面路由
- [ ] 實作頁面間的導航邏輯
- [ ] 添加返回和重置功能

#### 步驟 3.4：實作狀態持久化
- [ ] 實作搜索選擇的狀態保存
- [ ] 添加表單資料的暫存功能
- [ ] 實作頁面重載時的狀態恢復
- [ ] 處理導航過程中的資料保持

### 階段四：優化與測試

#### 步驟 4.1：UI/UX 優化
- [ ] 實作搜索和內容切換的動畫效果
- [ ] 優化不同螢幕尺寸的顯示效果
- [ ] 添加載入指示器和錯誤處理
- [ ] 實作用戶友好的提示訊息

#### 步驟 4.2：效能優化
- [ ] 優化組件的重新渲染邏輯
- [ ] 實作內容的懶加載
- [ ] 添加圖片和資源的快取機制
- [ ] 優化搜索和切換的響應速度

#### 步驟 4.3：測試與驗證
- [ ] 實作單元測試
- [ ] 進行整合測試
- [ ] 測試不同設備的兼容性
- [ ] 驗證所有功能的正確性

## 🎨 UI/UX 設計規範

### 主頁面佈局（手機版優先）
```
┌─────────────────────────────────────┐
│ 🎫 Ticket Booking System           │
├─────────────────────────────────────┤
│                                     │
│ 🔍 Search for Destinations         │
│ ┌─────────────────────────────────┐ │
│ │ Type destination...        🔍   │ │ ← 可輸入的下拉選單
│ └─────────────────────────────────┘ │
│ Suggestions:                        │
│ • 🚉 Munich Central                 │
│ • 🏰 Neuschwanstein Castle          │
│                                     │
│ [ Search ] 🔍                       │
│                                     │
├─────────────────────────────────────┤
│ 📋 Ticket Application              │
│                                     │
│ [Dynamic Content Area]              │
│                                     │
│ IF Station Selected:                │
│ • Train Search Form                 │
│ • Departure/Arrival Selection       │
│ • Date/Time Picker                  │
│ • Passenger Count                   │
│                                     │
│ IF Attraction Selected:             │
│ • Castle Ticket Form (existing)    │
│ • Multiple Tickets Support          │
│ • Name/Age/Session Selection        │
│ • Email Input                       │
│                                     │
│ [Price Summary]                     │
│ [ Book Now ]                        │
│                                     │
└─────────────────────────────────────┘
```

### 搜索組件設計（多語言關鍵字搜索）
```
┌─────────────────────────────────────┐
│ 🔍 Where would you like to go?      │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 慕尼黑                     🔍   │ │ ← 用戶輸入中文
│ └─────────────────────────────────┘ │
│                                     │
│ Filtered Results:                   │
│ ┌─────────────────────────────────┐ │
│ │ 🚉 Munich Central               │ │ ← 匹配到的選項
│ │   Munich Central Railway Station│ │
│ │   Keywords: 慕尼黑, München      │ │ ← 顯示匹配的關鍵字
│ └─────────────────────────────────┘ │
│                                     │
│ Example searches:                   │
│ • "新天鵝堡" → Neuschwanstein Castle │
│ • "Uffizi" → Uffizi Gallery         │
│ • "佛羅倫斯" → Florence SMN          │
│ • "Milano" → Milano Centrale        │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │         🔍 Search               │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 📱 響應式設計考量

### 手機版 (Mobile) - 主要設計目標
- 搜索框全寬度顯示，支援輸入和下拉選擇
- 搜索建議以卡片形式垂直排列
- 票券申請區域在搜索框下方
- 表單元素堆疊顯示，易於觸控操作
- 按鈕全寬度設計，符合手機操作習慣

### 平板版 (Tablet)
- 搜索框居中顯示
- 內容區域可以並排顯示
- 表單使用兩列佈局
- 按鈕適中寬度

### 網頁版 (Web)
- 搜索框固定寬度居中
- 內容區域使用卡片式設計
- 表單使用多列佈局
- 滑鼠懸停效果

## 🔄 狀態管理架構

### MainPageProvider 狀態
```dart
class MainPageProvider extends ChangeNotifier {
  SearchOption? selectedOption;
  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic> formData = {};
  
  // 搜索選項列表（Hard Code + 多語言關鍵字）
  List<SearchOption> get searchOptions => [
    SearchOption(
      id: 'munich_central',
      name: 'Munich Central',
      type: SearchOptionType.station,
      description: 'Munich Central Railway Station',
      stationCode: 'ST_L6NN3P6K',
      icon: '🚉',
      keywords: ['Munich','München','Munich Hbf','München Hauptbahnhof','Munich Central','Munich Main Station','慕尼黑','慕尼黑中央車站'],
    ),
    SearchOption(
      id: 'neuschwanstein_castle',
      name: 'Neuschwanstein Castle', 
      type: SearchOptionType.attraction,
      description: 'Fairy-tale Castle in Bavaria',
      ticketTypes: ['adult', 'under18'],
      icon: '🏰',
      keywords: ['新天鵝堡','新天鹅堡','Neuschwanstein','Neuschwanstein Castle','Schloss Neuschwanstein','노이슈반슈타인성','Château de Neuschwanstein'],
    ),
    SearchOption(
      id: 'uffizi_gallery',
      name: 'Uffizi Gallery',
      type: SearchOptionType.attraction,
      description: 'World-famous Renaissance art museum in Florence',
      ticketTypes: ['adult', 'under18'],
      icon: '🎨',
      keywords: ['烏菲齊美術館','烏菲茲美術館','Uffizi','Uffizi Gallery','Galleria degli Uffizi','Galerie des Offices','Галерея Уффици'],
    ),
    // ... 其他選項
  ];
  
  // 選擇搜索選項
  void selectOption(SearchOption option);
  
  // 執行搜索
  Future<void> performSearch();
  
  // 多語言關鍵字搜索
  List<SearchOption> searchByKeywords(String query) {
    if (query.isEmpty) return searchOptions;
    
    return searchOptions.where((option) {
      // 搜索名稱
      if (option.name.toLowerCase().contains(query.toLowerCase())) {
        return true;
      }
      // 搜索描述
      if (option.description.toLowerCase().contains(query.toLowerCase())) {
        return true;
      }
      // 搜索關鍵字
      return option.keywords.any((keyword) => 
        keyword.toLowerCase().contains(query.toLowerCase())
      );
    }).toList();
  }
  
  // 清除選擇
  void clearSelection();
  
  // 更新表單資料
  void updateFormData(String key, dynamic value);
  
  // 驗證表單
  bool validateForm();
  
  // 提交申請
  Future<void> submitApplication();
}
```

## 🧪 測試資料

### 多語言搜索測試案例
```json
{
  "searchTestCases": [
    {
      "input": "慕尼黑",
      "expectedResults": ["Munich Central"],
      "description": "中文搜索德國城市"
    },
    {
      "input": "新天鵝堡", 
      "expectedResults": ["Neuschwanstein Castle"],
      "description": "中文搜索德國景點"
    },
    {
      "input": "Uffizi",
      "expectedResults": ["Uffizi Gallery"],
      "description": "英文搜索義大利景點"
    },
    {
      "input": "佛羅倫斯",
      "expectedResults": ["Florence SMN"],
      "description": "中文搜索義大利車站"
    },
    {
      "input": "Milano",
      "expectedResults": ["Milano Centrale"],
      "description": "義大利文搜索車站"
    },
    {
      "input": "München",
      "expectedResults": ["Munich Central"],
      "description": "德文搜索慕尼黑車站"
    },
    {
      "input": "노이슈반슈타인성",
      "expectedResults": ["Neuschwanstein Castle"],
      "description": "韓文搜索新天鵝堡"
    }
  ]
}
```

### 搜索選項完整測試資料
```json
{
  "searchOptions": [
    {
      "id": "munich_central",
      "name": "Munich Central",
      "type": "station",
      "description": "Munich Central Railway Station",
      "icon": "🚉",
      "stationCode": "ST_L6NN3P6K",
      "keywords": ["Munich","München","Munich Hbf","München Hauptbahnhof","Munich Central","Munich Main Station","慕尼黑","慕尼黑中央車站"],
      "image": "assets/images/munich_central.jpg"
    },
    {
      "id": "neuschwanstein_castle",
      "name": "Neuschwanstein Castle",
      "type": "attraction", 
      "description": "Fairy-tale Castle in Bavaria",
      "icon": "🏰",
      "keywords": ["新天鵝堡","新天鹅堡","Neuschwanstein","Neuschwanstein Castle","Schloss Neuschwanstein","노이슈반슈타인성","Château de Neuschwanstein"],
      "image": "assets/images/neuschwanstein_castle.png"
    },
    {
      "id": "uffizi_gallery",
      "name": "Uffizi Gallery",
      "type": "attraction",
      "description": "World-famous Renaissance art museum in Florence",
      "icon": "🎨",
      "keywords": ["烏菲齊美術館","烏菲茲美術館","Uffizi","Uffizi Gallery","Galleria degli Uffizi","Galerie des Offices","Галерея Уффици"],
      "image": "assets/images/uffizi_galleries.png"
    }
  ]
}
```

## 📋 開發優先順序

### 第一階段：基礎架構（2-3 天）
1. 建立主頁面和基本佈局
2. 實作搜索組件和選項管理
3. 設計內容顯示區域
4. 建立狀態管理架構

### 第二階段：內容整合（2-3 天）
1. 實作車站票券申請區塊
2. 整合景點門票申請區塊
3. 實作動態內容切換
4. 完善表單驗證邏輯

### 第三階段：功能完善（2 天）
1. 整合支付流程
2. 完善導航邏輯
3. 實作狀態持久化
4. 添加錯誤處理

### 第四階段：優化測試（1-2 天）
1. UI/UX 優化和動畫效果
2. 響應式設計調整
3. 效能優化
4. 全面測試和 bug 修復

## 🎯 成功標準

### 功能完整性
- ✅ 使用者可以選擇車站或景點
- ✅ 多語言關鍵字搜索功能正常運作
- ✅ 支援中文、英文、德文、義大利文、韓文等多語言輸入
- ✅ 搜索結果即時篩選和顯示
- ✅ 動態內容正確顯示
- ✅ 車站票券申請功能完整
- ✅ 景點門票申請功能完整
- ✅ 支付流程整合成功

### 用戶體驗
- ✅ 多語言搜索操作直觀簡單
- ✅ 即時搜索結果反饋
- ✅ 關鍵字匹配準確度高
- ✅ 內容切換流暢自然
- ✅ 表單填寫體驗良好
- ✅ 錯誤處理用戶友好
- ✅ 響應式設計適配良好

### 技術品質
- ✅ 程式碼結構清晰
- ✅ 狀態管理正確
- ✅ 組件復用性高
- ✅ 效能表現良好

## 📝 備註

### 技術考量
- 使用現有的 Provider 狀態管理模式
- 保持與現有 UI 風格一致
- 確保在不同螢幕尺寸下的良好體驗
- 為未來擴展更多選項預留空間

### 業務邏輯
- 車站票券和景點門票使用統一的申請流程
- 支援多種票券類型和價格計算
- 價格以歐元計算，統一貨幣顯示
- 搜索選項可以輕鬆擴展和配置

### 擴展性考量
- 搜索選項支援動態配置
- 內容區塊支援插件式擴展
- 表單組件支援不同票券類型
- 支付流程支援多種票券整合

---

**總預估開發時間：7-10 天**
**複雜度：中高**
**依賴項目：現有的票券申請系統和支付流程**
