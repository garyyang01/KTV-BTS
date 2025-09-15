# AI Command Box 開發指南

## 📋 專案概述

### 現有系統分析
基於對現有 KTV-BTS (Ticket Trip Booking System) 的分析，目前系統具備以下功能：

**核心功能：**
- 🚉 火車票搜索與預訂 (G2Rail API 整合)
- 🏰 景點門票預訂 (新天鵝堡等)
- 💳 Stripe 支付整合
- 📧 郵件通知服務
- 📱 多平台支援 (iOS, Android, Web)

**現有 UI 結構：**
- `MainPage`: 主頁面，包含搜索功能和底部導航
- `SearchBarWidget`: 智能搜索組件，支援多語言關鍵字
- `ContentDisplayWidget`: 內容展示組件
- 底部導航：Home, Bundle, My Tickets, Settings

## 🎯 AI Command Box 需求分析

### 核心目標
在主頁面新增一個 AI Command Box，讓用戶可以透過自然語言對話直接購買車票和門票。

### 功能需求

#### 1. 基礎對話功能
- **自然語言理解**: 解析用戶的旅行需求
- **多語言支援**: 中文、英文、德文、義大利文等
- **上下文記憶**: 記住對話歷史和用戶偏好
- **智能建議**: 基於用戶輸入提供相關建議

#### 2. 票務整合功能
- **火車票預訂**: 整合現有 `RailBookingService`
- **景點門票**: 整合現有票務系統
- **價格查詢**: 即時價格和可用性檢查
- **預訂確認**: 完整的預訂流程

#### 3. 支付整合
- **支付處理**: 整合現有 Stripe 支付系統
- **訂單管理**: 與現有訂單系統整合
- **確認通知**: 郵件和應用內通知

## 🏗️ 技術架構設計 (n8n AI Agent 整合)

### 1. 整體架構流程

```
用戶輸入 → Flutter App → n8n AI Agent → AI 分析 → JSON 回傳 → 後端驗證 → 自動訂票
```

### 2. AI Command Box Widget 結構

```dart
// lib/widgets/ai_command_box_widget.dart
class AICommandBoxWidget extends StatefulWidget {
  final Function(BookingConfirmation?)? onBookingGenerated;
  final Function(String)? onConversationUpdate;
  
  const AICommandBoxWidget({
    super.key,
    this.onBookingGenerated,
    this.onConversationUpdate,
  });
}

class _AICommandBoxWidgetState extends State<AICommandBoxWidget> {
  final N8nAIService _aiService = N8nAIService();
  final List<ConversationMessage> _messages = [];
  ConversationState _currentState = ConversationState.idle;
  
  // 處理用戶輸入
  Future<void> _handleUserInput(String input) async {
    setState(() {
      _messages.add(ConversationMessage.user(input));
      _currentState = ConversationState.processing;
    });
    
    try {
      final response = await _aiService.processMessage(input, _messages);
      
      setState(() {
        _messages.add(ConversationMessage.ai(response.message));
        _currentState = response.state;
      });
      
      // 如果 AI 返回完整的預訂 JSON，觸發預訂流程
      if (response.bookingData != null) {
        widget.onBookingGenerated?.call(response.bookingData!);
      }
    } catch (e) {
      setState(() {
        _messages.add(ConversationMessage.error('抱歉，處理您的請求時發生錯誤。'));
        _currentState = ConversationState.idle;
      });
    }
  }
}
```

### 3. n8n AI 服務整合

```dart
// lib/services/n8n_ai_service.dart
class N8nAIService {
  static const String _n8nWebhookUrl = 'https://your-n8n-instance.com/webhook/ai-booking';
  final http.Client _httpClient = http.Client();
  
  /// 發送消息到 n8n AI Agent
  Future<AIResponse> processMessage(
    String userInput, 
    List<ConversationMessage> conversationHistory
  ) async {
    try {
      final requestBody = {
        'user_input': userInput,
        'conversation_history': conversationHistory.map((m) => m.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _generateSessionId(),
      };
      
      print('🚀 發送到 n8n AI Agent: $userInput');
      
      final response = await _httpClient.post(
        Uri.parse(_n8nWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_getN8nApiKey()}',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return AIResponse.fromN8nResponse(responseData);
      } else {
        throw Exception('n8n API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ n8n AI 服務錯誤: $e');
      return AIResponse.error('處理請求時發生錯誤，請稍後重試。');
    }
  }
  
  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  String _getN8nApiKey() {
    // 從環境變數或配置文件獲取 API Key
    return const String.fromEnvironment('N8N_API_KEY', defaultValue: '');
  }
}
```

### 4. AI 回應和預訂資料模型

```dart
// lib/models/ai_models.dart
class AIResponse {
  final String message;
  final ConversationState state;
  final BookingConfirmation? bookingData;
  final bool isComplete;
  final Map<String, dynamic>? metadata;

  const AIResponse({
    required this.message,
    required this.state,
    this.bookingData,
    this.isComplete = false,
    this.metadata,
  });

  /// 從 n8n 回應創建 AIResponse
  factory AIResponse.fromN8nResponse(Map<String, dynamic> data) {
    return AIResponse(
      message: data['message'] ?? '',
      state: _parseConversationState(data['state']),
      bookingData: data['booking_data'] != null 
          ? BookingConfirmation.fromJson(data['booking_data'])
          : null,
      isComplete: data['is_complete'] ?? false,
      metadata: data['metadata'],
    );
  }

  factory AIResponse.error(String message) {
    return AIResponse(
      message: message,
      state: ConversationState.error,
    );
  }

  static ConversationState _parseConversationState(String? state) {
    switch (state) {
      case 'collecting_info': return ConversationState.collectingInfo;
      case 'confirming_booking': return ConversationState.confirmingBooking;
      case 'completed': return ConversationState.completed;
      case 'error': return ConversationState.error;
      default: return ConversationState.idle;
    }
  }
}

/// n8n AI Agent 回傳的標準預訂資料格式
class BookingConfirmation {
  final String ticketType;        // 票券類型: "neuschwanstein", "train", etc.
  final DateTime date;            // 預訂日期
  final String timeSlot;          // 時段: "morning", "afternoon"
  final int adultCount;           // 成人數量
  final int childCount;           // 兒童數量
  final String email;             // 客戶信箱
  final String? customerName;     // 客戶姓名 (可選)
  final Map<String, dynamic>? additionalInfo; // 額外資訊

  const BookingConfirmation({
    required this.ticketType,
    required this.date,
    required this.timeSlot,
    required this.adultCount,
    required this.childCount,
    required this.email,
    this.customerName,
    this.additionalInfo,
  });

  /// 從 n8n JSON 回應創建預訂確認
  factory BookingConfirmation.fromJson(Map<String, dynamic> json) {
    return BookingConfirmation(
      ticketType: json['ticket_type'] ?? '',
      date: DateTime.parse(json['date']),
      timeSlot: json['time_slot'] ?? 'morning',
      adultCount: json['adult_count'] ?? 0,
      childCount: json['child_count'] ?? 0,
      email: json['email'] ?? '',
      customerName: json['customer_name'],
      additionalInfo: json['additional_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_type': ticketType,
      'date': date.toIso8601String(),
      'time_slot': timeSlot,
      'adult_count': adultCount,
      'child_count': childCount,
      'email': email,
      'customer_name': customerName,
      'additional_info': additionalInfo,
    };
  }

  /// 驗證預訂資料是否完整
  bool isValid() {
    return ticketType.isNotEmpty &&
           email.isNotEmpty &&
           (adultCount > 0 || childCount > 0) &&
           _isValidEmail(email);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// 轉換為現有系統的 PaymentRequest
  PaymentRequest toPaymentRequest() {
    return PaymentRequest(
      customerName: customerName ?? 'AI 預訂客戶',
      isAdult: adultCount > 0,
      time: timeSlot == 'morning' ? 'Morning' : 'Afternoon',
      currency: 'EUR',
      description: _generateDescription(),
      email: email,
      adultCount: adultCount,
      childCount: childCount,
    );
  }

  String _generateDescription() {
    switch (ticketType.toLowerCase()) {
      case 'neuschwanstein':
        return '新天鵝堡門票 - $timeSlot 時段';
      case 'train':
        return '火車票預訂';
      default:
        return '票券預訂 - $ticketType';
    }
  }
}

class ConversationMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  factory ConversationMessage.user(String content) {
    return ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.userInput,
      timestamp: DateTime.now(),
    );
  }

  factory ConversationMessage.ai(String content) {
    return ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.aiResponse,
      timestamp: DateTime.now(),
    );
  }

  factory ConversationMessage.error(String content) {
    return ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.error,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

enum MessageType {
  userInput,
  aiResponse,
  systemNotification,
  bookingConfirmation,
  error,
}

enum ConversationState {
  idle,                // 閒置狀態
  collectingInfo,      // 收集資訊中
  confirmingBooking,   // 確認預訂中
  processing,          // 處理中
  completed,           // 完成
  error,              // 錯誤狀態
}
```

## 🎨 UI/UX 設計

### 1. AI Command Box 位置
- **位置**: 主頁面搜索區域下方
- **樣式**: 現代化聊天介面，與現有設計風格一致
- **動畫**: 平滑的展開/收合動畫

### 2. 對話介面設計

```dart
// 對話氣泡設計
Widget _buildMessageBubble(ConversationMessage message) {
  final isUser = message.type == MessageType.userInput;
  
  return Container(
    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) _buildAIAvatar(),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isUser 
                ? LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400])
                : LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade200]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (isUser) _buildUserAvatar(),
      ],
    ),
  );
}
```

### 3. 快速操作按鈕

```dart
// 常用操作快捷按鈕
Widget _buildQuickActions() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildQuickActionChip('🚄 搜索火車票', () => _handleQuickAction('search_trains')),
        _buildQuickActionChip('🏰 景點門票', () => _handleQuickAction('attraction_tickets')),
        _buildQuickActionChip('💰 查詢價格', () => _handleQuickAction('check_prices')),
        _buildQuickActionChip('📍 推薦路線', () => _handleQuickAction('recommend_routes')),
      ],
    ),
  );
}
```

## 🤖 AI 對話邏輯

### 1. 意圖識別規則

```dart
class IntentRecognizer {
  static UserIntent identifyIntent(String input) {
    final lowerInput = input.toLowerCase();
    
    // 火車票搜索關鍵字
    if (_containsAny(lowerInput, ['火車', 'train', 'railway', '班次', 'schedule'])) {
      return UserIntent.searchTrains;
    }
    
    // 預訂關鍵字
    if (_containsAny(lowerInput, ['預訂', 'book', 'reserve', '購買', 'buy'])) {
      return UserIntent.bookTickets;
    }
    
    // 價格查詢關鍵字
    if (_containsAny(lowerInput, ['價格', 'price', '多少錢', 'cost', '費用'])) {
      return UserIntent.checkPrice;
    }
    
    // 推薦關鍵字
    if (_containsAny(lowerInput, ['推薦', 'recommend', '建議', 'suggest'])) {
      return UserIntent.getRecommendations;
    }
    
    return UserIntent.unknown;
  }
}
```

### 2. 實體提取

```dart
class EntityExtractor {
  static Map<String, dynamic> extractEntities(String input) {
    Map<String, dynamic> entities = {};
    
    // 提取日期
    entities['date'] = _extractDate(input);
    
    // 提取地點
    entities['origin'] = _extractLocation(input, LocationType.origin);
    entities['destination'] = _extractLocation(input, LocationType.destination);
    
    // 提取人數
    entities['passenger_count'] = _extractPassengerCount(input);
    
    // 提取時間偏好
    entities['time_preference'] = _extractTimePreference(input);
    
    return entities;
  }
}
```

### 3. 對話流程管理

```dart
class ConversationFlow {
  ConversationState currentState = ConversationState.idle;
  Map<String, dynamic> collectedData = {};
  
  Future<AIResponse> processInput(String input) async {
    switch (currentState) {
      case ConversationState.idle:
        return await _handleIdleState(input);
      
      case ConversationState.collectingTravelInfo:
        return await _handleTravelInfoCollection(input);
      
      case ConversationState.showingOptions:
        return await _handleOptionSelection(input);
      
      case ConversationState.confirmingBooking:
        return await _handleBookingConfirmation(input);
      
      case ConversationState.processing:
        return AIResponse.waiting('正在處理您的請求...');
    }
  }
}
```

## 🔗 系統整合

### 1. 與現有搜索系統整合

```dart
class AISearchIntegration {
  final SearchBarWidget searchWidget;
  final RailBookingService railService;
  
  Future<List<SearchOption>> aiSearch(Map<String, dynamic> entities) async {
    // 將 AI 提取的實體轉換為搜索參數
    final searchCriteria = _convertEntitiesToCriteria(entities);
    
    // 使用現有搜索服務
    final results = await SearchService.performSearch(
      searchCriteria.query,
      filterType: searchCriteria.type,
    );
    
    return results.map((r) => r.option).toList();
  }
}
```

### 2. 與預訂系統整合

```dart
class AIBookingIntegration {
  final RailBookingService railService;
  final StripePaymentService paymentService;
  
  Future<BookingResult> processAIBooking(AIBookingRequest request) async {
    try {
      // 1. 創建搜索條件
      final criteria = RailSearchCriteria.fromAIRequest(request);
      
      // 2. 搜索可用選項
      final searchResult = await railService.searchAndGetResults(criteria);
      
      if (!searchResult.success) {
        return BookingResult.failure('搜索失敗: ${searchResult.errorMessage}');
      }
      
      // 3. 選擇最佳選項 (基於 AI 偏好)
      final selectedSolution = _selectBestOption(
        searchResult.data!.solutions, 
        request.preferences
      );
      
      // 4. 創建訂單
      final orderRequest = OnlineOrderRequest.fromAIBooking(request, selectedSolution);
      final orderResult = await railService.createOnlineOrder(request: orderRequest);
      
      if (!orderResult.success) {
        return BookingResult.failure('創建訂單失敗: ${orderResult.errorMessage}');
      }
      
      // 5. 處理支付
      final paymentResult = await _processPayment(request.paymentInfo, orderResult.data!);
      
      return BookingResult.success(
        orderId: orderResult.data!.id,
        paymentId: paymentResult.paymentIntentId,
      );
      
    } catch (e) {
      return BookingResult.failure('預訂過程發生錯誤: $e');
    }
  }
}
```

## 🔄 n8n 工作流程設計

### 1. n8n Workflow 架構

```json
{
  "workflow_name": "AI_Booking_Agent",
  "description": "處理自然語言預訂請求的 AI Agent",
  "nodes": [
    {
      "name": "Webhook_Trigger",
      "type": "webhook",
      "description": "接收來自 Flutter App 的用戶輸入"
    },
    {
      "name": "AI_Language_Processing",
      "type": "openai",
      "description": "使用 OpenAI/Claude 進行自然語言理解",
      "prompt_template": "你是一個專業的旅行預訂助手。分析用戶輸入並提取預訂資訊..."
    },
    {
      "name": "Information_Validator",
      "type": "code",
      "description": "驗證提取的資訊是否完整"
    },
    {
      "name": "Response_Generator",
      "type": "code", 
      "description": "根據資訊完整性生成回應"
    },
    {
      "name": "Booking_JSON_Creator",
      "type": "code",
      "description": "當資訊完整時創建預訂 JSON"
    }
  ]
}
```

### 2. AI Prompt 設計

```
系統角色: 你是一個專業的旅行預訂助手，專門處理新天鵝堡和火車票的預訂。

任務: 分析用戶輸入，提取預訂所需的關鍵資訊，並判斷資訊是否完整。

必要資訊:
- ticket_type: 票券類型 (neuschwanstein, train)
- date: 預訂日期 (YYYY-MM-DD 格式)
- time_slot: 時段 (morning/afternoon)
- adult_count: 成人數量
- child_count: 兒童數量  
- email: 客戶信箱

回應格式:
{
  "message": "回覆用戶的訊息",
  "state": "collecting_info|confirming_booking|completed",
  "extracted_info": {
    "ticket_type": "...",
    "date": "...",
    "time_slot": "...",
    "adult_count": 0,
    "child_count": 0,
    "email": "..."
  },
  "missing_fields": ["缺少的欄位"],
  "is_complete": false,
  "booking_data": null // 當 is_complete=true 時包含完整預訂資料
}

範例對話:
用戶: "我想要買新天鵝堡"
回應: 詢問日期、時段、人數、信箱

用戶: "10/2 早上 兩個人(一大一小) email:123@xxx.com"  
回應: 生成完整的 booking_data JSON
```

### 3. n8n 節點詳細配置

#### Webhook 節點
```javascript
// 接收 Flutter 請求
{
  "user_input": "我想要買新天鵝堡",
  "conversation_history": [...],
  "session_id": "unique_session_id",
  "timestamp": "2024-10-01T10:00:00Z"
}
```

#### AI 處理節點 (OpenAI/Claude)
```javascript
// Code 節點 - 預處理
const userInput = $json.user_input;
const history = $json.conversation_history || [];

// 構建完整的對話上下文
const contextMessages = history.map(msg => ({
  role: msg.type === 'userInput' ? 'user' : 'assistant',
  content: msg.content
}));

contextMessages.push({
  role: 'user', 
  content: userInput
});

return {
  messages: contextMessages,
  user_input: userInput,
  session_id: $json.session_id
};
```

#### 資訊驗證節點
```javascript
// Code 節點 - 驗證提取的資訊
const aiResponse = JSON.parse($json.choices[0].message.content);
const extractedInfo = aiResponse.extracted_info || {};

// 必要欄位檢查
const requiredFields = ['ticket_type', 'date', 'time_slot', 'email'];
const missingFields = requiredFields.filter(field => 
  !extractedInfo[field] || extractedInfo[field] === ''
);

// 人數檢查
if ((extractedInfo.adult_count || 0) + (extractedInfo.child_count || 0) === 0) {
  missingFields.push('passenger_count');
}

// 信箱格式驗證
if (extractedInfo.email && !extractedInfo.email.match(/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/)) {
  missingFields.push('valid_email');
}

const isComplete = missingFields.length === 0;

return {
  ...aiResponse,
  missing_fields: missingFields,
  is_complete: isComplete,
  extracted_info: extractedInfo
};
```

#### 回應生成節點
```javascript
// Code 節點 - 生成最終回應
const data = $json;

if (data.is_complete) {
  // 資訊完整，生成預訂確認
  const bookingData = {
    ticket_type: data.extracted_info.ticket_type,
    date: data.extracted_info.date,
    time_slot: data.extracted_info.time_slot,
    adult_count: parseInt(data.extracted_info.adult_count) || 0,
    child_count: parseInt(data.extracted_info.child_count) || 0,
    email: data.extracted_info.email,
    customer_name: data.extracted_info.customer_name || null
  };

  return {
    message: `完美！我已經為您準備好預訂資訊：
📅 日期: ${bookingData.date}
🕐 時段: ${bookingData.time_slot === 'morning' ? '上午' : '下午'}
👥 人數: ${bookingData.adult_count}大${bookingData.child_count}小
📧 信箱: ${bookingData.email}

請確認以上資訊無誤，我將為您進行預訂。`,
    state: 'confirming_booking',
    is_complete: true,
    booking_data: bookingData
  };
} else {
  // 資訊不完整，繼續收集
  return {
    message: data.message,
    state: 'collecting_info',
    is_complete: false,
    booking_data: null
  };
}
```

## 📱 用戶體驗流程 (n8n 整合版)

### 1. 完整對話流程範例

```
用戶: "我想要買新天鵝堡"
↓ (發送到 n8n)
n8n AI: "好的！我來幫您預訂新天鵝堡門票。請告訴我：
        📅 您希望哪一天參觀？
        🕐 偏好上午還是下午？
        👥 總共幾位？(請註明成人/兒童)
        📧 您的信箱地址？"

用戶: "10/2 早上 兩個人(一大一小) email:123@xxx.com"
↓ (發送到 n8n，AI 分析並提取資訊)
n8n AI: "完美！我已經為您準備好預訂資訊：
        📅 日期: 2024-10-02
        🕐 時段: 上午
        👥 人數: 1大1小
        📧 信箱: 123@xxx.com
        
        請確認以上資訊無誤，我將為您進行預訂。"
        
↓ (同時返回 booking_data JSON)
Flutter App: 顯示預訂確認介面，用戶點擊確認
↓ (後端驗證 JSON 並自動訂票)
系統: 自動處理預訂和支付流程
```

### 2. JSON 回傳格式範例

```json
{
  "message": "完美！我已經為您準備好預訂資訊...",
  "state": "confirming_booking",
  "is_complete": true,
  "booking_data": {
    "ticket_type": "neuschwanstein",
    "date": "2024-10-02",
    "time_slot": "morning",
    "adult_count": 1,
    "child_count": 1,
    "email": "123@xxx.com",
    "customer_name": null
  },
  "metadata": {
    "session_id": "1696147200000",
    "processed_at": "2024-10-01T10:00:00Z"
  }
}
```

### 2. 錯誤處理流程

```dart
class AIErrorHandler {
  static AIResponse handleError(AIError error) {
    switch (error.type) {
      case AIErrorType.missingInformation:
        return AIResponse.question(
          "抱歉，我需要更多信息。${error.missingFields.join('、')}是必需的。"
        );
      
      case AIErrorType.noResultsFound:
        return AIResponse.suggestion(
          "很抱歉，沒有找到符合條件的選項。要不要試試：\n"
          "• 調整出發時間\n"
          "• 選擇其他目的地\n"
          "• 查看推薦路線"
        );
      
      case AIErrorType.bookingFailed:
        return AIResponse.error(
          "預訂過程中出現問題：${error.message}\n"
          "請稍後重試或聯繫客服。"
        );
    }
  }
}
```

## 🔗 後端整合邏輯

### 1. 後端 JSON 驗證服務

```dart
// lib/services/booking_validation_service.dart
class BookingValidationService {
  /// 驗證 n8n 回傳的預訂 JSON 是否完整且有效
  static BookingValidationResult validateBookingData(Map<String, dynamic> jsonData) {
    try {
      final bookingConfirmation = BookingConfirmation.fromJson(jsonData);
      
      // 基礎驗證
      if (!bookingConfirmation.isValid()) {
        return BookingValidationResult.invalid('預訂資料不完整或格式錯誤');
      }
      
      // 日期驗證
      if (bookingConfirmation.date.isBefore(DateTime.now())) {
        return BookingValidationResult.invalid('預訂日期不能是過去的日期');
      }
      
      // 票券類型驗證
      if (!_isSupportedTicketType(bookingConfirmation.ticketType)) {
        return BookingValidationResult.invalid('不支援的票券類型: ${bookingConfirmation.ticketType}');
      }
      
      return BookingValidationResult.valid(bookingConfirmation);
      
    } catch (e) {
      return BookingValidationResult.invalid('JSON 解析錯誤: $e');
    }
  }
  
  static bool _isSupportedTicketType(String ticketType) {
    const supportedTypes = ['neuschwanstein', 'train', 'uffizi'];
    return supportedTypes.contains(ticketType.toLowerCase());
  }
}

class BookingValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BookingConfirmation? bookingData;
  
  const BookingValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.bookingData,
  });
  
  factory BookingValidationResult.valid(BookingConfirmation booking) {
    return BookingValidationResult._(
      isValid: true,
      bookingData: booking,
    );
  }
  
  factory BookingValidationResult.invalid(String error) {
    return BookingValidationResult._(
      isValid: false,
      errorMessage: error,
    );
  }
}
```

### 2. 自動訂票服務

```dart
// lib/services/auto_booking_service.dart
class AutoBookingService {
  final RailBookingService _railService;
  final StripePaymentService _paymentService;
  final TicketStorageService _storageService;
  
  AutoBookingService({
    required RailBookingService railService,
    required StripePaymentService paymentService,
    required TicketStorageService storageService,
  }) : _railService = railService,
       _paymentService = paymentService,
       _storageService = storageService;
  
  /// 根據 AI 生成的 JSON 自動處理訂票流程
  Future<AutoBookingResult> processAIBooking(BookingConfirmation booking) async {
    try {
      print('🤖 開始 AI 自動訂票流程');
      print('📋 預訂資料: ${booking.toJson()}');
      
      // 1. 根據票券類型選擇處理方式
      switch (booking.ticketType.toLowerCase()) {
        case 'neuschwanstein':
          return await _processAttractionBooking(booking);
        case 'train':
          return await _processTrainBooking(booking);
        default:
          return AutoBookingResult.failure('不支援的票券類型: ${booking.ticketType}');
      }
      
    } catch (e) {
      print('❌ AI 自動訂票失敗: $e');
      return AutoBookingResult.failure('自動訂票過程發生錯誤: $e');
    }
  }
  
  /// 處理景點門票預訂 (新天鵝堡等)
  Future<AutoBookingResult> _processAttractionBooking(BookingConfirmation booking) async {
    try {
      // 轉換為現有系統的 PaymentRequest
      final paymentRequest = booking.toPaymentRequest();
      
      // 創建支付意圖
      final paymentResponse = await _paymentService.createPaymentIntent(paymentRequest);
      
      if (!paymentResponse.success) {
        return AutoBookingResult.failure('創建支付失敗: ${paymentResponse.errorMessage}');
      }
      
      // 儲存預訂資料
      await _storageService.saveBookingData(booking);
      
      return AutoBookingResult.success(
        bookingId: DateTime.now().millisecondsSinceEpoch.toString(),
        paymentIntentId: paymentResponse.paymentIntentId!,
        clientSecret: paymentResponse.clientSecret!,
        totalAmount: _calculateTotalAmount(booking),
      );
      
    } catch (e) {
      return AutoBookingResult.failure('景點門票預訂失敗: $e');
    }
  }
  
  /// 處理火車票預訂
  Future<AutoBookingResult> _processTrainBooking(BookingConfirmation booking) async {
    try {
      // TODO: 實作火車票預訂邏輯
      // 這裡需要根據 booking 資料構建 RailSearchCriteria
      // 然後調用 _railService.searchAndGetResults()
      
      return AutoBookingResult.failure('火車票預訂功能開發中');
      
    } catch (e) {
      return AutoBookingResult.failure('火車票預訂失敗: $e');
    }
  }
  
  double _calculateTotalAmount(BookingConfirmation booking) {
    // 根據票券類型計算總金額
    switch (booking.ticketType.toLowerCase()) {
      case 'neuschwanstein':
        return (booking.adultCount * 19.0) + (booking.childCount * 1.0); // 成人€19, 兒童€1
      default:
        return 0.0;
    }
  }
}

class AutoBookingResult {
  final bool success;
  final String? errorMessage;
  final String? bookingId;
  final String? paymentIntentId;
  final String? clientSecret;
  final double? totalAmount;
  
  const AutoBookingResult._({
    required this.success,
    this.errorMessage,
    this.bookingId,
    this.paymentIntentId,
    this.clientSecret,
    this.totalAmount,
  });
  
  factory AutoBookingResult.success({
    required String bookingId,
    required String paymentIntentId,
    required String clientSecret,
    required double totalAmount,
  }) {
    return AutoBookingResult._(
      success: true,
      bookingId: bookingId,
      paymentIntentId: paymentIntentId,
      clientSecret: clientSecret,
      totalAmount: totalAmount,
    );
  }
  
  factory AutoBookingResult.failure(String error) {
    return AutoBookingResult._(
      success: false,
      errorMessage: error,
    );
  }
}
```

### 3. 主頁面整合邏輯

```dart
// lib/pages/main_page.dart - 新增 AI 整合部分
class _MainPageState extends State<MainPage> {
  // ... 現有代碼 ...
  
  /// 處理 AI 生成的預訂確認
  void _handleAIBookingGenerated(BookingConfirmation? booking) async {
    if (booking == null) return;
    
    try {
      // 1. 驗證預訂資料
      final validationResult = BookingValidationService.validateBookingData(booking.toJson());
      
      if (!validationResult.isValid) {
        _showErrorDialog('預訂資料驗證失敗', validationResult.errorMessage!);
        return;
      }
      
      // 2. 顯示預訂確認對話框
      final confirmed = await _showBookingConfirmationDialog(booking);
      
      if (!confirmed) return;
      
      // 3. 顯示載入指示器
      _showLoadingDialog('正在處理您的預訂...');
      
      // 4. 執行自動訂票
      final autoBookingService = AutoBookingService(
        railService: RailBookingService.defaultInstance(),
        paymentService: StripePaymentService(),
        storageService: TicketStorageService(),
      );
      
      final bookingResult = await autoBookingService.processAIBooking(booking);
      
      // 5. 隱藏載入指示器
      Navigator.of(context).pop();
      
      if (bookingResult.success) {
        // 6. 導航到支付頁面
        final paymentRequest = booking.toPaymentRequest();
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: paymentRequest,
        );
      } else {
        _showErrorDialog('自動訂票失敗', bookingResult.errorMessage!);
      }
      
    } catch (e) {
      Navigator.of(context).pop(); // 隱藏載入指示器
      _showErrorDialog('處理預訂時發生錯誤', e.toString());
    }
  }
  
  /// 顯示預訂確認對話框
  Future<bool> _showBookingConfirmationDialog(BookingConfirmation booking) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.confirmation_number, color: Colors.blue.shade600),
            SizedBox(width: 8),
            Text('確認預訂'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('請確認以下預訂資訊：', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildConfirmationRow('票券類型', _getTicketTypeDisplayName(booking.ticketType)),
            _buildConfirmationRow('日期', booking.date.toString().split(' ')[0]),
            _buildConfirmationRow('時段', booking.timeSlot == 'morning' ? '上午' : '下午'),
            _buildConfirmationRow('人數', '${booking.adultCount}大${booking.childCount}小'),
            _buildConfirmationRow('信箱', booking.email),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '確認後將自動處理預訂和支付流程',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('確認預訂'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTicketTypeDisplayName(String ticketType) {
    switch (ticketType.toLowerCase()) {
      case 'neuschwanstein': return '新天鵝堡門票';
      case 'train': return '火車票';
      case 'uffizi': return '烏菲茲美術館';
      default: return ticketType;
    }
  }
  
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
  
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('確定'),
          ),
        ],
      ),
    );
  }
}
```

## 🔧 實作步驟 (n8n 整合版)

### Phase 1: n8n 工作流程建立 (Week 1)
1. ✅ 設置 n8n 實例和 Webhook
2. ✅ 配置 AI 節點 (OpenAI/Claude)
3. ✅ 實作資訊提取和驗證邏輯
4. ✅ 測試完整的 n8n 工作流程

### Phase 2: Flutter 前端整合 (Week 2)
1. ✅ 創建 `N8nAIService` 和 API 整合
2. ✅ 實作 `AICommandBoxWidget` UI 組件
3. ✅ 建立對話介面和狀態管理
4. ✅ 整合到 `MainPage` 主頁面

### Phase 3: 後端驗證和自動訂票 (Week 3)
1. ✅ 實作 `BookingValidationService`
2. ✅ 建立 `AutoBookingService` 自動訂票邏輯
3. ✅ 整合現有支付和預訂系統
4. ✅ 實作預訂確認和錯誤處理

### Phase 4: 測試和優化 (Week 4)
1. ✅ 端到端測試完整流程
2. ✅ 性能優化和錯誤處理
3. ✅ 用戶體驗優化
4. ✅ 文檔完善和部署準備

## 🎯 關鍵詞建議

### 搜索相關
- **火車票**: train, railway, ticket, 火車, 班次, schedule, departure, arrival
- **景點**: attraction, castle, museum, gallery, 景點, 城堡, 美術館
- **地點**: Munich, Florence, Neuschwanstein, 慕尼黑, 佛羅倫斯, 新天鵝堡
- **時間**: tomorrow, today, morning, afternoon, 明天, 今天, 上午, 下午

### 預訂相關
- **預訂**: book, reserve, purchase, buy, 預訂, 購買, 訂票
- **人數**: adult, child, person, passenger, 成人, 兒童, 人, 乘客
- **支付**: pay, payment, credit card, 支付, 付款, 信用卡

### 查詢相關
- **價格**: price, cost, fee, how much, 價格, 費用, 多少錢
- **時間**: schedule, timetable, when, 時刻表, 班次, 什麼時候
- **可用性**: available, vacancy, 可用, 有沒有

### 幫助相關
- **推薦**: recommend, suggest, advice, 推薦, 建議
- **幫助**: help, assist, support, 幫助, 協助, 客服
- **取消**: cancel, refund, 取消, 退款

## 🚀 技術考量

### 1. 性能優化
- **懶加載**: AI 組件按需載入
- **緩存**: 對話歷史和常用回應緩存
- **異步處理**: 所有 AI 處理都在後台進行

### 2. 多語言支援
- **本地化**: 支援中文、英文、德文等
- **語言檢測**: 自動檢測用戶輸入語言
- **翻譯整合**: 必要時整合翻譯服務

### 3. 離線支援
- **基礎功能**: 離線時提供基本對話功能
- **緩存策略**: 緩存常用回應和數據
- **同步機制**: 網絡恢復時同步數據

### 4. 安全性
- **輸入驗證**: 嚴格驗證用戶輸入
- **數據加密**: 敏感對話數據加密存儲
- **隱私保護**: 遵循數據隱私法規

## 📊 成功指標

### 用戶體驗指標
- **對話成功率**: >85% 的對話能成功完成預訂
- **用戶滿意度**: 4.5/5 星以上
- **使用頻率**: 50% 的用戶選擇使用 AI 預訂

### 技術指標
- **響應時間**: AI 回應時間 <2 秒
- **準確率**: 意圖識別準確率 >90%
- **穩定性**: 99.5% 的可用性

### 業務指標
- **轉換率**: AI 對話到預訂的轉換率 >60%
- **平均訂單價值**: 通過 AI 預訂的平均訂單價值
- **客服減負**: 減少 30% 的人工客服查詢

## 🔮 未來擴展

### 1. 高級 AI 功能
- **個性化推薦**: 基於用戶歷史的個性化建議
- **情感分析**: 理解用戶情緒並相應調整回應
- **多輪對話**: 支援複雜的多輪對話場景

### 2. 整合擴展
- **語音輸入**: 支援語音轉文字輸入
- **圖像識別**: 識別用戶上傳的圖片中的地點
- **社交分享**: 分享行程到社交媒體

### 3. 智能化升級
- **機器學習**: 從用戶互動中學習改進
- **預測分析**: 預測用戶需求和偏好
- **自動化**: 更多自動化的預訂和管理功能

## ⚡ 重新定義的 MVP Scope

### 🎯 MVP 目標
**建立前端 AI Command Box 與 n8n 的基礎整合，驗證完整的預訂流程**

### 📋 MVP Scope 定義

#### ✅ 包含功能 (Core Features)

**1. 首頁 AI Command Box (30 分鐘)**
- 簡潔的輸入框和發送按鈕
- 基礎的載入狀態指示
- 整合到現有主頁面設計

**2. n8n Webhook 整合 (20 分鐘)**
- HTTP POST 請求到 n8n webhook
- 基礎錯誤處理和重試機制
- 回應資料解析

**3. 票券確認頁面 (30 分鐘)**
- 根據 n8n 回應自動填入預訂資訊
- 清晰的確認介面設計
- 確認按鈕觸發付款流程

**4. 付款流程連接 (10 分鐘)**
- 整合現有 Stripe 支付系統
- 將確認資料轉換為 PaymentRequest

#### ❌ 不包含 (Out of Scope)
- n8n AI Agent 內部邏輯 (由您單獨處理)
- 複雜的錯誤處理和邊界情況
- 美化的動畫效果
- 多語言支援

### 🚀 1.5 小時實作計劃

#### **Phase 1: AI Command Box Widget (30 分鐘)**

```dart
// lib/widgets/ai_command_input_widget.dart
class AICommandInputWidget extends StatefulWidget {
  final Function(String)? onCommandSubmitted;
  
  const AICommandInputWidget({super.key, this.onCommandSubmitted});
  
  @override
  State<AICommandInputWidget> createState() => _AICommandInputWidgetState();
}

class _AICommandInputWidgetState extends State<AICommandInputWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  
  Future<void> _submitCommand() async {
    if (_controller.text.trim().isEmpty) return;
    
    final command = _controller.text.trim();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await widget.onCommandSubmitted?.call(command);
    } finally {
      setState(() {
        _isLoading = false;
      });
      _controller.clear();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題區域
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 智能預訂助手',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                    Text(
                      '用自然語言告訴我您的需求',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // 輸入區域
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: '例如：我想要買新天鵝堡門票...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _submitCommand(),
                  maxLines: 2,
                ),
              ),
              
              SizedBox(width: 12),
              
              // 發送按鈕
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _submitCommand,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // 提示文字
          if (!_isLoading) ...[
            SizedBox(height: 8),
            Text(
              '💡 提示：請包含日期、時段、人數和信箱資訊',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

#### **Phase 2: n8n Webhook 服務 (20 分鐘)**

```dart
// lib/services/n8n_webhook_service.dart
class N8nWebhookService {
  static const String _webhookUrl = 'https://your-n8n-instance.com/webhook/ai-booking';
  final http.Client _httpClient = http.Client();
  
  /// 發送用戶指令到 n8n AI Agent
  Future<N8nResponse> sendCommand(String userCommand) async {
    try {
      print('🚀 發送指令到 n8n: $userCommand');
      
      final requestBody = {
        'user_input': userCommand,
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _generateSessionId(),
      };
      
      final response = await _httpClient.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'KTV-BTS-Flutter-App',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));
      
      print('📊 n8n 回應狀態: ${response.statusCode}');
      print('📦 n8n 回應內容: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return N8nResponse.fromJson(responseData);
      } else {
        throw Exception('n8n Webhook 錯誤: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ n8n Webhook 呼叫失敗: $e');
      return N8nResponse.error('無法連接到 AI 服務，請稍後重試。');
    }
  }
  
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// n8n 回應資料模型
class N8nResponse {
  final bool success;
  final String? message;
  final BookingData? bookingData;
  final String? errorMessage;
  
  const N8nResponse({
    required this.success,
    this.message,
    this.bookingData,
    this.errorMessage,
  });
  
  factory N8nResponse.fromJson(Map<String, dynamic> json) {
    return N8nResponse(
      success: json['success'] ?? false,
      message: json['message'],
      bookingData: json['booking_data'] != null 
          ? BookingData.fromJson(json['booking_data'])
          : null,
    );
  }
  
  factory N8nResponse.error(String message) {
    return N8nResponse(
      success: false,
      errorMessage: message,
    );
  }
}

/// 預訂資料模型
class BookingData {
  final String ticketType;
  final String date;
  final String timeSlot;
  final int adultCount;
  final int childCount;
  final String email;
  final String? customerName;
  
  const BookingData({
    required this.ticketType,
    required this.date,
    required this.timeSlot,
    required this.adultCount,
    required this.childCount,
    required this.email,
    this.customerName,
  });
  
  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      ticketType: json['ticket_type'] ?? '',
      date: json['date'] ?? '',
      timeSlot: json['time_slot'] ?? 'morning',
      adultCount: json['adult_count'] ?? 0,
      childCount: json['child_count'] ?? 0,
      email: json['email'] ?? '',
      customerName: json['customer_name'],
    );
  }
  
  /// 轉換為現有系統的 PaymentRequest
  PaymentRequest toPaymentRequest() {
    return PaymentRequest(
      customerName: customerName ?? 'AI 預訂客戶',
      isAdult: adultCount > 0,
      time: timeSlot == 'morning' ? 'Morning' : 'Afternoon',
      currency: 'EUR',
      description: _getTicketDescription(),
      email: email,
    );
  }
  
  String _getTicketDescription() {
    switch (ticketType.toLowerCase()) {
      case 'neuschwanstein':
        return '新天鵝堡門票 - ${timeSlot == "morning" ? "上午" : "下午"}時段';
      case 'train':
        return '火車票預訂';
      default:
        return '票券預訂';
    }
  }
  
  double getTotalAmount() {
    switch (ticketType.toLowerCase()) {
      case 'neuschwanstein':
        return (adultCount * 19.0) + (childCount * 1.0);
      default:
        return 0.0;
    }
  }
}
```

#### **Phase 3: 票券確認頁面 (30 分鐘)**

```dart
// lib/pages/ai_booking_confirmation_page.dart
class AIBookingConfirmationPage extends StatelessWidget {
  final BookingData bookingData;
  
  const AIBookingConfirmationPage({
    super.key,
    required this.bookingData,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('確認預訂資訊'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.blue.shade600],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI 成功提示
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 成功解析您的需求！',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        Text(
                          '請確認以下預訂資訊是否正確',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // 預訂資訊卡片
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '預訂詳情',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildInfoRow(
                    Icons.confirmation_number,
                    '票券類型',
                    _getTicketTypeDisplay(bookingData.ticketType),
                    Colors.purple,
                  ),
                  
                  _buildInfoRow(
                    Icons.calendar_today,
                    '參觀日期',
                    bookingData.date,
                    Colors.blue,
                  ),
                  
                  _buildInfoRow(
                    Icons.access_time,
                    '時段',
                    bookingData.timeSlot == 'morning' ? '上午' : '下午',
                    Colors.orange,
                  ),
                  
                  _buildInfoRow(
                    Icons.people,
                    '人數',
                    '${bookingData.adultCount} 成人, ${bookingData.childCount} 兒童',
                    Colors.green,
                  ),
                  
                  _buildInfoRow(
                    Icons.email,
                    '信箱',
                    bookingData.email,
                    Colors.red,
                  ),
                  
                  if (bookingData.customerName != null)
                    _buildInfoRow(
                      Icons.person,
                      '姓名',
                      bookingData.customerName!,
                      Colors.indigo,
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // 價格資訊
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '總金額',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '€${bookingData.getTotalAmount().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // 確認按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _proceedToPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment),
                    SizedBox(width: 8),
                    Text(
                      '確認並前往付款',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 返回按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple.shade600,
                  side: BorderSide(color: Colors.purple.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('返回修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTicketTypeDisplay(String ticketType) {
    switch (ticketType.toLowerCase()) {
      case 'neuschwanstein':
        return '新天鵝堡門票';
      case 'train':
        return '火車票';
      default:
        return ticketType;
    }
  }
  
  void _proceedToPayment(BuildContext context) {
    // 轉換為 PaymentRequest 並導航到支付頁面
    final paymentRequest = bookingData.toPaymentRequest();
    
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: paymentRequest,
    );
  }
}
```

#### **Phase 4: 主頁面整合 (10 分鐘)**

```dart
// 在 lib/pages/main_page.dart 中新增
class _MainPageState extends State<MainPage> {
  final N8nWebhookService _n8nService = N8nWebhookService();
  
  // ... 現有代碼 ...
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... 現有代碼 ...
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... 現有的 Welcome section ...
              
              const SizedBox(height: 24),
              
              // 新增 AI Command Box
              AICommandInputWidget(
                onCommandSubmitted: _handleAICommand,
              ),
              
              const SizedBox(height: 24),
              
              // ... 現有的 Search section 和其他內容 ...
            ],
          ),
        ),
      ),
    );
  }
  
  /// 處理 AI 指令提交
  Future<void> _handleAICommand(String command) async {
    try {
      // 顯示載入指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('AI 正在分析您的需求...'),
            ],
          ),
        ),
      );
      
      // 呼叫 n8n webhook
      final response = await _n8nService.sendCommand(command);
      
      // 關閉載入指示器
      Navigator.of(context).pop();
      
      if (response.success && response.bookingData != null) {
        // 成功：導航到確認頁面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIBookingConfirmationPage(
              bookingData: response.bookingData!,
            ),
          ),
        );
      } else {
        // 失敗：顯示錯誤訊息
        _showErrorDialog(
          '處理失敗',
          response.errorMessage ?? response.message ?? '無法處理您的請求，請重新嘗試。',
        );
      }
      
    } catch (e) {
      // 關閉載入指示器
      Navigator.of(context).pop();
      
      _showErrorDialog('發生錯誤', '處理您的請求時發生錯誤：$e');
    }
  }
  
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('確定'),
          ),
        ],
      ),
    );
  }
}
```

### 🎯 成功驗證標準

#### **功能驗證**
- ✅ AI Command Box 可以接收用戶輸入
- ✅ 成功呼叫 n8n webhook 並接收回應
- ✅ 根據回應自動填入預訂資訊
- ✅ 票券確認頁面顯示正確
- ✅ 可以順利進入付款流程

#### **整合驗證**
- ✅ 與現有主頁面無縫整合
- ✅ 與現有支付系統正確連接
- ✅ 資料格式轉換正確

### ⏰ 時間分配

```
00:00-00:30  AI Command Box Widget 開發
00:30-00:50  n8n Webhook 服務整合
00:50-01:20  票券確認頁面實作
01:20-01:30  主頁面整合和測試
```

### 🔗 n8n Webhook 預期格式

**請求格式：**
```json
{
  "user_input": "我想要買新天鵝堡 10/15 上午 1大1小 test@example.com",
  "timestamp": "2024-10-01T10:00:00Z",
  "session_id": "session_1696147200000"
}
```

**回應格式：**
```json
{
  "success": true,
  "message": "預訂資訊已準備完成",
  "booking_data": {
    "ticket_type": "neuschwanstein",
    "date": "2024-10-15",
    "time_slot": "morning",
    "adult_count": 1,
    "child_count": 1,
    "email": "test@example.com",
    "customer_name": null
  }
}
```

---

*本文檔將隨著開發進度持續更新和完善。*
