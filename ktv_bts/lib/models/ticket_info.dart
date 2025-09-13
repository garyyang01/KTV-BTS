/// Individual ticket information model
class TicketInfo {
  final String familyName;
  final String givenName;
  final bool isAdult;
  final String session; // "Morning" or "Afternoon"
  final String arrivalTime; // "YYYY-MM-DD" format
  final double price;

  const TicketInfo({
    required this.familyName,
    required this.givenName,
    required this.isAdult,
    required this.session,
    required this.arrivalTime,
    required this.price,
  });

  /// Get full name (FamilyName + GivenName)
  String get fullName => '$familyName $givenName';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'FamilyName': familyName,
      'GivenName': givenName,
      'IsAdult': isAdult,
      'Session': session,
      'ArrivalTime': arrivalTime,
      'Prize': price,
    };
  }

  /// Create from JSON
  factory TicketInfo.fromJson(Map<String, dynamic> json) {
    return TicketInfo(
      familyName: json['FamilyName'] as String,
      givenName: json['GivenName'] as String,
      isAdult: json['IsAdult'] as bool,
      session: json['Session'] as String,
      arrivalTime: json['ArrivalTime'] as String,
      price: (json['Prize'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'TicketInfo(familyName: $familyName, givenName: $givenName, isAdult: $isAdult, session: $session, arrivalTime: $arrivalTime, price: $price)';
  }
}
