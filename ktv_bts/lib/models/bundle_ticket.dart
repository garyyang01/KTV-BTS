/// Bundle Ticket Model
/// Represents a purchased bundle ticket
class BundleTicket {
  final String id;
  final String bundleId;
  final String bundleName;
  final String location;
  final double priceEur;
  final DateTime bookingDate;
  final DateTime tourDate;
  final List<BundleParticipant> participants;
  final String paymentRefno;
  final String status;

  const BundleTicket({
    required this.id,
    required this.bundleId,
    required this.bundleName,
    required this.location,
    required this.priceEur,
    required this.bookingDate,
    required this.tourDate,
    required this.participants,
    required this.paymentRefno,
    required this.status,
  });

  factory BundleTicket.fromJson(Map<String, dynamic> json) {
    return BundleTicket(
      id: json['id'] as String,
      bundleId: json['bundleId'] as String,
      bundleName: json['bundleName'] as String,
      location: json['location'] as String,
      priceEur: (json['priceEur'] as num).toDouble(),
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      tourDate: DateTime.parse(json['tourDate'] as String),
      participants: (json['participants'] as List)
          .map((p) => BundleParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      paymentRefno: json['paymentRefno'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bundleId': bundleId,
      'bundleName': bundleName,
      'location': location,
      'priceEur': priceEur,
      'bookingDate': bookingDate.toIso8601String(),
      'tourDate': tourDate.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'paymentRefno': paymentRefno,
      'status': status,
    };
  }

  String get formattedPrice => '€${priceEur.toStringAsFixed(2)}';
  String get totalPrice => '€${(priceEur * participants.length).toStringAsFixed(2)}';
}

/// Bundle Participant Model
class BundleParticipant {
  final String firstName;
  final String lastName;
  final String email;
  final String passportNumber;

  const BundleParticipant({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passportNumber,
  });

  factory BundleParticipant.fromJson(Map<String, dynamic> json) {
    return BundleParticipant(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      passportNumber: json['passportNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'passportNumber': passportNumber,
    };
  }

  String get fullName => '$firstName $lastName';
}
