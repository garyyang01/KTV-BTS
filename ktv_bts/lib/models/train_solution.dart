/// 火車班次解決方案模型
class TrainSolution {
  final String carrierCode;
  final String carrierDescription;
  final String carrierIcon;
  final List<TrainOffer> offers;
  final List<TrainInfo> trains;

  const TrainSolution({
    required this.carrierCode,
    required this.carrierDescription,
    required this.carrierIcon,
    required this.offers,
    required this.trains,
  });

  factory TrainSolution.fromJson(Map<String, dynamic> json) {
    print('🔍 TrainSolution.fromJson 接收到: ${json.keys.toList()}');
    
    // 處理不同的 API 回應結構
    String carrierCode = json['carrier_code'] as String? ?? 
                        json['carrier']?['code'] as String? ?? 
                        json['railway']?['code'] as String? ?? '';
    
    String carrierDescription = json['carrier_description'] as String? ?? 
                               json['carrier']?['description'] as String? ?? 
                               json['railway']?['name'] as String? ?? 
                               json['carrier']?['name'] as String? ?? '';
    
    String carrierIcon = json['carrier_icon'] as String? ?? 
                        json['carrier']?['icon'] as String? ?? 
                        json['railway']?['icon'] as String? ?? '';
    
    // 處理 offers 和 trains 陣列
    List<dynamic> offersList = json['offers'] as List<dynamic>? ?? [];
    List<dynamic> trainsList = json['trains'] as List<dynamic>? ?? [];
    
    // 如果沒有直接的 offers 和 trains，檢查 solutions 陣列
    if (offersList.isEmpty && trainsList.isEmpty && json.containsKey('solutions')) {
      List<dynamic> solutions = json['solutions'] as List<dynamic>? ?? [];
      print('🔍 檢查 solutions 陣列，找到 ${solutions.length} 個解決方案');
      
      for (var solution in solutions) {
        if (solution is Map<String, dynamic>) {
          // 從 solutions 中提取 offers 和 trains
          offersList.addAll(solution['offers'] as List<dynamic>? ?? []);
          trainsList.addAll(solution['trains'] as List<dynamic>? ?? []);
          
          // 檢查是否有 sections 陣列（更深的嵌套結構）
          List<dynamic> sections = solution['sections'] as List<dynamic>? ?? [];
          print('🔍 檢查 sections 陣列，找到 ${sections.length} 個區段');
          
          for (var section in sections) {
            if (section is Map<String, dynamic>) {
              // 從 sections 中提取 offers 和 trains
              offersList.addAll(section['offers'] as List<dynamic>? ?? []);
              trainsList.addAll(section['trains'] as List<dynamic>? ?? []);
            }
          }
        }
      }
    }
    
    print('🔍 最終找到 ${offersList.length} 個 offers 和 ${trainsList.length} 個 trains');
    
    return TrainSolution(
      carrierCode: carrierCode,
      carrierDescription: carrierDescription,
      carrierIcon: carrierIcon,
      offers: offersList
          .map((offer) => TrainOffer.fromJson(offer as Map<String, dynamic>))
          .toList(),
      trains: trainsList
          .map((train) => TrainInfo.fromJson(train as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'TrainSolution(carrier: $carrierDescription, offers: ${offers.length}, trains: ${trains.length})';
  }
}

/// 火車班次優惠模型
class TrainOffer {
  final String code;
  final String description;
  final String detail;
  final String helpUrl;
  final String? restriction;
  final String ticketType;
  final String seatType;
  final String refundType;
  final String confirmAgain;
  final String changeType;
  final List<TrainService> services;

  const TrainOffer({
    required this.code,
    required this.description,
    required this.detail,
    required this.helpUrl,
    this.restriction,
    required this.ticketType,
    required this.seatType,
    required this.refundType,
    required this.confirmAgain,
    required this.changeType,
    required this.services,
  });

  factory TrainOffer.fromJson(Map<String, dynamic> json) {
    return TrainOffer(
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      helpUrl: json['help_url'] as String? ?? '',
      restriction: json['restriction'] as String?,
      ticketType: json['ticket_type'] as String? ?? '',
      seatType: json['seat_type'] as String? ?? '',
      refundType: json['refund_type'] as String? ?? '',
      confirmAgain: json['confirm_again'] as String? ?? '',
      changeType: json['change_type'] as String? ?? '',
      services: (json['services'] as List<dynamic>? ?? [])
          .map((service) => TrainService.fromJson(service as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'TrainOffer(description: $description, services: ${services.length})';
  }
}

/// 火車服務模型
class TrainService {
  final String code;
  final String description;
  final String detail;
  final String? featurePhoto;
  final TrainAvailability available;
  final TrainPrice price;
  final TrainPrice averageUnitPrice;
  final String bookingCode;
  final String bookingType;
  final int rank;
  final String? helpUrl;

  const TrainService({
    required this.code,
    required this.description,
    required this.detail,
    this.featurePhoto,
    required this.available,
    required this.price,
    required this.averageUnitPrice,
    required this.bookingCode,
    required this.bookingType,
    required this.rank,
    this.helpUrl,
  });

  factory TrainService.fromJson(Map<String, dynamic> json) {
    return TrainService(
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      featurePhoto: json['feature_photo'] as String?,
      available: TrainAvailability.fromJson(json['available'] as Map<String, dynamic>? ?? {}),
      price: TrainPrice.fromJson(json['price'] as Map<String, dynamic>? ?? {}),
      averageUnitPrice: TrainPrice.fromJson(json['average_unit_price'] as Map<String, dynamic>? ?? {}),
      bookingCode: json['booking_code'] as String? ?? '',
      bookingType: json['booking_type'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      helpUrl: json['help_url'] as String?,
    );
  }

  @override
  String toString() {
    return 'TrainService(description: $description, price: ${price.toString()})';
  }
}

/// 火車可用性模型
class TrainAvailability {
  final int seats;

  const TrainAvailability({
    required this.seats,
  });

  factory TrainAvailability.fromJson(Map<String, dynamic> json) {
    return TrainAvailability(
      seats: json['seats'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'TrainAvailability(seats: $seats)';
  }
}

/// 火車價格模型
class TrainPrice {
  final String currency;
  final int cents;

  const TrainPrice({
    required this.currency,
    required this.cents,
  });

  factory TrainPrice.fromJson(Map<String, dynamic> json) {
    return TrainPrice(
      currency: json['currency'] as String? ?? 'EUR',
      cents: json['cents'] as int? ?? 0,
    );
  }

  /// 獲取格式化的價格字符串
  String get formattedPrice {
    return '${currency} ${(cents / 100).toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return formattedPrice;
  }
}

/// 火車信息模型
class TrainInfo {
  final String number;
  final String trainNumber;
  final String type;
  final String trainIcon;
  final String typeName;
  final String? featurePhoto;
  final TrainStation from;
  final TrainStation to;
  final DateTime departure;
  final DateTime arrival;
  final String? helpUrl;
  final List<TrainStop> stops;
  final String? departurePlatform;
  final String? arrivalPlatform;

  const TrainInfo({
    required this.number,
    required this.trainNumber,
    required this.type,
    required this.trainIcon,
    required this.typeName,
    this.featurePhoto,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    this.helpUrl,
    required this.stops,
    this.departurePlatform,
    this.arrivalPlatform,
  });

  factory TrainInfo.fromJson(Map<String, dynamic> json) {
    return TrainInfo(
      number: json['number'] as String? ?? '',
      trainNumber: json['train_number'] as String? ?? '',
      type: json['type'] as String? ?? '',
      trainIcon: json['train_icon'] as String? ?? '',
      typeName: json['type_name'] as String? ?? '',
      featurePhoto: json['feature_photo'] as String?,
      from: TrainStation.fromJson(json['from'] as Map<String, dynamic>? ?? {}),
      to: TrainStation.fromJson(json['to'] as Map<String, dynamic>? ?? {}),
      departure: DateTime.parse(json['departure'] as String? ?? DateTime.now().toIso8601String()),
      arrival: DateTime.parse(json['arrival'] as String? ?? DateTime.now().toIso8601String()),
      helpUrl: json['help_url'] as String?,
      stops: (json['stops'] as List<dynamic>? ?? [])
          .map((stop) => TrainStop.fromJson(stop as Map<String, dynamic>))
          .toList(),
      departurePlatform: json['departure_platform'] as String?,
      arrivalPlatform: json['arrival_platform'] as String?,
    );
  }

  /// 獲取行程時間
  Duration get duration {
    return arrival.difference(departure);
  }

  /// 獲取格式化的行程時間
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  String toString() {
    return 'TrainInfo(number: $number, from: ${from.name}, to: ${to.name})';
  }
}

/// 火車站模型
class TrainStation {
  final String code;
  final String name;
  final String localName;
  final String? helpUrl;

  const TrainStation({
    required this.code,
    required this.name,
    required this.localName,
    this.helpUrl,
  });

  factory TrainStation.fromJson(Map<String, dynamic> json) {
    return TrainStation(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      localName: json['local_name'] as String? ?? '',
      helpUrl: json['help_url'] as String?,
    );
  }

  @override
  String toString() {
    return 'TrainStation(name: $name, localName: $localName)';
  }
}

/// 火車停靠站模型
class TrainStop {
  final String code;
  final String name;
  final String localName;
  final String? helpUrl;
  final String? platform;
  final String? departureTime;
  final String? arrivalTime;

  const TrainStop({
    required this.code,
    required this.name,
    required this.localName,
    this.helpUrl,
    this.platform,
    this.departureTime,
    this.arrivalTime,
  });

  factory TrainStop.fromJson(Map<String, dynamic> json) {
    return TrainStop(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      localName: json['local_name'] as String? ?? '',
      helpUrl: json['help_url'] as String?,
      platform: json['platform'] as String?,
      departureTime: json['departure_time'] as String?,
      arrivalTime: json['arrival_time'] as String?,
    );
  }

  @override
  String toString() {
    return 'TrainStop(name: $name, localName: $localName)';
  }
}
