/// Model for G2Rail online_orders API request
class OnlineOrderRequest {
  final List<Passenger> passengers;
  final List<String> sections;
  final bool seatReserved;
  final String memo;

  const OnlineOrderRequest({
    required this.passengers,
    required this.sections,
    required this.seatReserved,
    required this.memo,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'passengers': passengers.map((p) => p.toJson()).toList(),
      'sections': sections,
      'seat_reserved': seatReserved,
      'memo': memo,
    };
  }

  /// Create from JSON
  factory OnlineOrderRequest.fromJson(Map<String, dynamic> json) {
    return OnlineOrderRequest(
      passengers: (json['passengers'] as List)
          .map((p) => Passenger.fromJson(p as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List).cast<String>(),
      seatReserved: json['seat_reserved'] as bool,
      memo: json['memo'] as String,
    );
  }
}

/// Passenger information for online order
class Passenger {
  final String lastName;
  final String firstName;
  final String birthdate;
  final String passport;
  final String email;
  final String phone;
  final String gender;

  const Passenger({
    required this.lastName,
    required this.firstName,
    required this.birthdate,
    required this.passport,
    required this.email,
    required this.phone,
    required this.gender,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'last_name': lastName,
      'first_name': firstName,
      'birthdate': birthdate,
      'passport': passport,
      'email': email,
      'phone': phone,
      'gender': gender,
    };
  }

  /// Create from JSON
  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
      birthdate: json['birthdate'] as String,
      passport: json['passport'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      gender: json['gender'] as String,
    );
  }
}
