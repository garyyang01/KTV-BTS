import 'ticket_request.dart';
import 'train_solution.dart';

/// Payment request model for KTV booking
class PaymentRequest {
  final String customerName;
  final bool isAdult;
  final String time; // "Morning" or "Afternoon"
  final double amount; // Will be calculated automatically
  final String currency; // Fixed to EUR
  final String? description;
  final TicketRequest? ticketRequest; // New field for ticket request
  
  // 火車票相關字段（用於組合支付）
  final TrainInfo? trainInfo;
  final TrainOffer? trainOffer;
  final TrainService? trainService;
  final double? trainTicketAmount; // 火車票金額

  const PaymentRequest({
    required this.customerName,
    required this.isAdult,
    required this.time,
    this.amount = 0.0, // Will be calculated based on isAdult
    this.currency = 'EUR', // Fixed to EUR
    this.description,
    this.ticketRequest,
    this.trainInfo,
    this.trainOffer,
    this.trainService,
    this.trainTicketAmount,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'is_adult': isAdult,
      'time': time,
      'amount': amount,
      'currency': currency,
      'description': description,
      'ticket_request': ticketRequest?.toJson(),
    };
  }

  /// Create from JSON
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      customerName: json['customer_name'] as String,
      isAdult: json['is_adult'] as bool,
      time: json['time'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      description: json['description'] as String?,
      ticketRequest: json['ticket_request'] != null 
          ? TicketRequest.fromJson(json['ticket_request'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 創建火車票專用的 PaymentRequest
  factory PaymentRequest.forTrainTicket({
    required String customerName,
    required TrainInfo train,
    required TrainOffer offer,
    required TrainService service,
  }) {
    final amount = service.price.cents / 100.0; // 將 cents 轉換為 EUR
    final description = '火車票 - ${train.number} (慕尼黑 → 福森)';
    
    // Debug: Print train ticket price details
    print('🚄 Train Ticket PaymentRequest Creation:');
    print('  - service.price.cents: ${service.price.cents}');
    print('  - service.price.currency: ${service.price.currency}');
    print('  - service.price.formattedPrice: ${service.price.formattedPrice}');
    print('  - calculated amount: $amount');
    print('  - train.number: ${train.number}');
    print('  - offer.description: ${offer.description}');
    print('  - service.description: ${service.description}');
    
    return PaymentRequest(
      customerName: customerName,
      isAdult: true, // 火車票預設為成人票
      time: 'Train Journey', // 火車行程時間
      amount: amount,
      currency: service.price.currency,
      description: description,
      ticketRequest: null, // 火車票不需要 TicketRequest
      trainInfo: train,
      trainOffer: offer,
      trainService: service,
      trainTicketAmount: amount,
    );
  }

  /// 創建組合支付（門票+火車票）的 PaymentRequest
  factory PaymentRequest.forCombinedPayment({
    required PaymentRequest originalTicketRequest,
    required TrainInfo train,
    required TrainOffer offer,
    required TrainService service,
  }) {
    final trainAmount = service.price.cents / 100.0;
    final totalAmount = originalTicketRequest.amount + trainAmount;
    
    final description = '新天鵝堡門票 + 火車票 - ${train.number} (慕尼黑 → 福森)';
    
    print('🎫🚄 Combined PaymentRequest Creation:');
    print('  - Original ticket amount: ${originalTicketRequest.amount}');
    print('  - Train ticket amount: $trainAmount');
    print('  - Total amount: $totalAmount');
    
    return PaymentRequest(
      customerName: originalTicketRequest.customerName,
      isAdult: originalTicketRequest.isAdult,
      time: originalTicketRequest.time,
      amount: totalAmount,
      currency: originalTicketRequest.currency,
      description: description,
      ticketRequest: originalTicketRequest.ticketRequest,
      trainInfo: train,
      trainOffer: offer,
      trainService: service,
      trainTicketAmount: trainAmount,
    );
  }

  /// 檢查是否為組合支付（包含火車票）
  bool get isCombinedPayment => trainInfo != null && trainTicketAmount != null;

  /// 獲取門票金額（不含火車票）
  double get ticketOnlyAmount => isCombinedPayment 
      ? amount - (trainTicketAmount ?? 0.0)
      : amount;

  @override
  String toString() {
    return 'PaymentRequest(customerName: $customerName, isAdult: $isAdult, time: $time, amount: $amount, currency: $currency)';
  }
}
