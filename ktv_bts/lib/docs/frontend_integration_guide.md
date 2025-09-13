# 前端整合指南 (Frontend Integration Guide)

## 🌐 前端如何處理信用卡支付

### 方式 1: Stripe Elements (應用內支付) - 推薦

#### 前端 HTML
```html
<!DOCTYPE html>
<html>
<head>
    <title>KTV 支付</title>
    <script src="https://js.stripe.com/v3/"></script>
</head>
<body>
    <h1>KTV 預訂支付</h1>
    
    <!-- 客戶資訊表單 -->
    <form id="payment-form">
        <div>
            <label>客戶姓名:</label>
            <input type="text" id="customer-name" value="張三" required>
        </div>
        
        <div>
            <label>客戶類型:</label>
            <select id="customer-type">
                <option value="true">成人</option>
                <option value="false">兒童</option>
            </select>
        </div>
        
        <div>
            <label>時段:</label>
            <select id="time-slot">
                <option value="Morning">上午</option>
                <option value="Afternoon">下午</option>
            </select>
        </div>
        
        <!-- Stripe Elements 信用卡輸入框 -->
        <div id="card-element">
            <!-- Stripe 會在這裡創建信用卡輸入框 -->
        </div>
        
        <!-- 錯誤訊息 -->
        <div id="card-errors" role="alert"></div>
        
        <!-- 支付按鈕 -->
        <button id="submit-payment">支付</button>
    </form>
    
    <!-- 支付結果 -->
    <div id="payment-result"></div>
</body>
</html>
```

#### 前端 JavaScript
```javascript
// 初始化 Stripe
const stripe = Stripe('pk_test_your_public_key_here');

// 創建 Stripe Elements
const elements = stripe.elements();
const cardElement = elements.create('card', {
    style: {
        base: {
            fontSize: '16px',
            color: '#424770',
            '::placeholder': {
                color: '#aab7c4',
            },
        },
    },
});

// 掛載信用卡輸入框
cardElement.mount('#card-element');

// 處理輸入錯誤
cardElement.on('change', ({error}) => {
    const displayError = document.getElementById('card-errors');
    if (error) {
        displayError.textContent = error.message;
    } else {
        displayError.textContent = '';
    }
});

// 處理支付表單提交
document.getElementById('payment-form').addEventListener('submit', async (event) => {
    event.preventDefault();
    
    const submitButton = document.getElementById('submit-payment');
    const resultDiv = document.getElementById('payment-result');
    
    // 禁用支付按鈕
    submitButton.disabled = true;
    submitButton.textContent = '處理中...';
    
    try {
        // 1. 獲取表單數據
        const customerName = document.getElementById('customer-name').value;
        const isAdult = document.getElementById('customer-type').value === 'true';
        const time = document.getElementById('time-slot').value;
        
        // 2. 調用後端 API 創建支付意圖
        const response = await fetch('/api/create-payment-intent', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                customer_name: customerName,
                is_adult: isAdult,
                time: time,
                currency: 'EUR'
            })
        });
        
        const data = await response.json();
        
        if (!data.success) {
            throw new Error(data.error_message || '創建支付意圖失敗');
        }
        
        // 3. 使用 Stripe 確認支付
        const {error, paymentIntent} = await stripe.confirmCardPayment(data.client_secret, {
            payment_method: {
                card: cardElement,
                billing_details: {
                    name: customerName,
                },
            }
        });
        
        if (error) {
            // 支付失敗
            resultDiv.innerHTML = `
                <div style="color: red;">
                    <h3>支付失敗</h3>
                    <p>${error.message}</p>
                </div>
            `;
        } else if (paymentIntent.status === 'succeeded') {
            // 支付成功
            resultDiv.innerHTML = `
                <div style="color: green;">
                    <h3>支付成功！</h3>
                    <p>支付 ID: ${paymentIntent.id}</p>
                    <p>金額: €${(paymentIntent.amount / 100).toFixed(2)}</p>
                    <p>狀態: ${paymentIntent.status}</p>
                </div>
            `;
        }
        
    } catch (error) {
        resultDiv.innerHTML = `
            <div style="color: red;">
                <h3>發生錯誤</h3>
                <p>${error.message}</p>
            </div>
        `;
    } finally {
        // 重新啟用支付按鈕
        submitButton.disabled = false;
        submitButton.textContent = '支付';
    }
});
```

### 方式 2: Stripe Checkout (跳轉到 Stripe 頁面)

#### 前端 JavaScript
```javascript
async function redirectToCheckout() {
    try {
        // 1. 創建 Checkout Session
        const response = await fetch('/api/create-checkout-session', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                customer_name: "張三",
                is_adult: true,
                time: "Morning",
                currency: "EUR"
            })
        });
        
        const { session_id } = await response.json();
        
        // 2. 跳轉到 Stripe Checkout
        const stripe = Stripe('pk_test_your_public_key_here');
        const { error } = await stripe.redirectToCheckout({
            sessionId: session_id
        });
        
        if (error) {
            console.error('跳轉失敗:', error);
        }
        
    } catch (error) {
        console.error('創建 Checkout Session 失敗:', error);
    }
}

// 調用函數
redirectToCheckout();
```

## 🔧 後端 API 端點範例

### 1. 創建支付意圖端點
```dart
// 在您的後端服務中添加
@Post('/api/create-payment-intent')
Future<Map<String, dynamic>> createPaymentIntent(@Body() Map<String, dynamic> request) async {
  try {
    final paymentRequest = PaymentRequest.fromJson(request);
    final paymentService = StripePaymentService();
    await paymentService.initialize();
    
    final response = await paymentService.createPaymentIntent(paymentRequest);
    
    return response.toJson();
  } catch (e) {
    return {
      'success': false,
      'error_message': e.toString()
    };
  }
}
```

### 2. 創建 Checkout Session 端點 (用於跳轉支付)
```dart
@Post('/api/create-checkout-session')
Future<Map<String, dynamic>> createCheckoutSession(@Body() Map<String, dynamic> request) async {
  try {
    final paymentRequest = PaymentRequest.fromJson(request);
    final paymentService = StripePaymentService();
    await paymentService.initialize();
    
    // 創建支付意圖
    final response = await paymentService.createPaymentIntent(paymentRequest);
    
    if (!response.success) {
      throw Exception(response.errorMessage);
    }
    
    // 創建 Checkout Session
    final session = await stripe.checkout.sessions.create(
      payment_intent_data: {
        'id': response.paymentIntentId,
      },
      mode: 'payment',
      success_url: 'https://your-website.com/success',
      cancel_url: 'https://your-website.com/cancel',
    );
    
    return {
      'success': true,
      'session_id': session.id
    };
  } catch (e) {
    return {
      'success': false,
      'error_message': e.toString()
    };
  }
}
```

## 📱 移動端整合 (Flutter/React Native)

### Flutter 整合
```dart
// 使用 flutter_stripe 套件
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KTV 支付')),
      body: Column(
        children: [
          // 客戶資訊表單
          TextField(
            decoration: InputDecoration(labelText: '客戶姓名'),
            controller: customerNameController,
          ),
          
          // Stripe 支付按鈕
          ElevatedButton(
            onPressed: () async {
              await _handlePayment();
            },
            child: Text('支付'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handlePayment() async {
    try {
      // 1. 創建支付意圖
      final response = await http.post(
        Uri.parse('https://your-api.com/api/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_name': customerNameController.text,
          'is_adult': true,
          'time': 'Morning',
        }),
      );
      
      final data = json.decode(response.body);
      
      // 2. 確認支付
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: data['client_secret'],
        data: PaymentMethodData.card(
          billingDetails: BillingDetails(
            name: customerNameController.text,
          ),
        ),
      );
      
      // 支付成功
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('支付成功！')),
      );
      
    } catch (e) {
      // 支付失敗
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('支付失敗: $e')),
      );
    }
  }
}
```

## 🔐 安全性注意事項

1. **Public Key**: 可以在前端使用
2. **Secret Key**: 只能在後端使用
3. **HTTPS**: 所有支付相關請求必須使用 HTTPS
4. **驗證**: 後端需要驗證所有支付請求
5. **日誌**: 不要在日誌中記錄敏感支付資訊

## 📋 總結

- **Stripe Elements**: 在您的應用內嵌入支付表單，無需跳轉
- **Stripe Checkout**: 跳轉到 Stripe 的支付頁面
- **我們的 Service**: 提供後端 API 來創建支付意圖
- **前端**: 使用 Stripe.js 處理實際的支付流程
