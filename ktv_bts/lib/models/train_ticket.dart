/// 火車票資料模型
class TrainTicket {
  final String ticketId;           // 票券ID
  final String originStation;      // 起始站
  final String destinationStation; // 終點站
  final String trainName;          // 名稱(車種)
  final String trainType;          // 車種類型
  final double price;              // 票價 (EUR)
  final String departureTime;      // 出發時間
  final String arrivalTime;        // 到達時間
  final String duration;           // 行程時間

  const TrainTicket({
    required this.ticketId,
    required this.originStation,
    required this.destinationStation,
    required this.trainName,
    required this.trainType,
    required this.price,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
  });

  /// 從 JSON 建立 TrainTicket 物件
  factory TrainTicket.fromJson(Map<String, dynamic> json) {
    return TrainTicket(
      ticketId: json['TicketId'] as String,
      originStation: json['OriginStation'] as String,
      destinationStation: json['DestinationStation'] as String,
      trainName: json['TrainName'] as String,
      trainType: json['TrainType'] as String,
      price: (json['Price'] as num).toDouble(),
      departureTime: json['DepartureTime'] as String,
      arrivalTime: json['ArrivalTime'] as String,
      duration: json['Duration'] as String,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'TicketId': ticketId,
      'OriginStation': originStation,
      'DestinationStation': destinationStation,
      'TrainName': trainName,
      'TrainType': trainType,
      'Price': price,
      'DepartureTime': departureTime,
      'ArrivalTime': arrivalTime,
      'Duration': duration,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainTicket && other.ticketId == ticketId;
  }

  @override
  int get hashCode => ticketId.hashCode;

  @override
  String toString() {
    return 'TrainTicket(ticketId: $ticketId, trainName: $trainName, price: €$price)';
  }
}
