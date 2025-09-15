/// Individual ticket information model
class TicketInfo {
  final String familyName;
  final String givenName;
  final bool isAdult;
  final String session; // "Morning" or "Afternoon"
  final String arrivalTime; // "YYYY-MM-DD" format
  final double price;
  
  // New fields for enhanced API request
  final String? id; // Random ID: tickettrip_ + 16 characters
  final String? type; // "Train", "Entrance", or "Bundle"
  final String? entranceName; // Name of the entrance ticket
  final String? bundleName; // Name of the bundle (currently empty)
  final String? from; // Departure location
  final String? to; // Destination location
  final String? phone; // Phone number
  final String? passportNumber; // Passport number
  final String? birthDate; // Birth date in "YYYY-MM-DD" format
  final String? gender; // Gender

  const TicketInfo({
    required this.familyName,
    required this.givenName,
    required this.isAdult,
    required this.session,
    required this.arrivalTime,
    required this.price,
    this.id,
    this.type,
    this.entranceName,
    this.bundleName,
    this.from,
    this.to,
    this.phone,
    this.passportNumber,
    this.birthDate,
    this.gender,
  });

  /// Get full name (FamilyName + GivenName)
  String get fullName => '$familyName $givenName';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'FamilyName': familyName,
      'GivenName': givenName,
      'IsAdult': isAdult,
      'Session': session,
      'ArrivalTime': arrivalTime,
      'Prize': price,
      'Type': type,
      'EntranceName': entranceName,
      'BundleName': bundleName,
      'From': from,
      'To': to,
      'Phone': phone,
      'PassportNumber': passportNumber,
      'BirthDate': birthDate,
      'Gender': gender,
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
      id: json['Id'] as String?,
      type: json['Type'] as String?,
      entranceName: json['EntranceName'] as String?,
      bundleName: json['BundleName'] as String?,
      from: json['From'] as String?,
      to: json['To'] as String?,
      phone: json['Phone'] as String?,
      passportNumber: json['PassportNumber'] as String?,
      birthDate: json['BirthDate'] as String?,
      gender: json['Gender'] as String?,
    );
  }

  @override
  String toString() {
    return 'TicketInfo(familyName: $familyName, givenName: $givenName, isAdult: $isAdult, session: $session, arrivalTime: $arrivalTime, price: $price)';
  }
}
