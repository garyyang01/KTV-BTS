/// Model for G2Rail online_orders API response
class OnlineOrderResponse {
  final String id;
  final Railway railway;
  final Station from;
  final Station to;
  final String departure;
  final String arrival;
  final Price paymentPrice;
  final Price chargingPrice;
  final Price rebateAmount;
  final List<PassengerResponse> passengers;
  final List<Ticket> tickets;

  const OnlineOrderResponse({
    required this.id,
    required this.railway,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.paymentPrice,
    required this.chargingPrice,
    required this.rebateAmount,
    required this.passengers,
    required this.tickets,
  });

  /// Create from JSON
  factory OnlineOrderResponse.fromJson(Map<String, dynamic> json) {
    return OnlineOrderResponse(
      id: json['id'] as String,
      railway: Railway.fromJson(json['railway'] as Map<String, dynamic>),
      from: Station.fromJson(json['from'] as Map<String, dynamic>),
      to: Station.fromJson(json['to'] as Map<String, dynamic>),
      departure: json['departure'] as String,
      arrival: json['arrival'] as String,
      paymentPrice: Price.fromJson(json['payment_price'] as Map<String, dynamic>),
      chargingPrice: Price.fromJson(json['charging_price'] as Map<String, dynamic>),
      rebateAmount: Price.fromJson(json['rebate_amount'] as Map<String, dynamic>),
      passengers: (json['passengers'] as List)
          .map((p) => PassengerResponse.fromJson(p as Map<String, dynamic>))
          .toList(),
      tickets: (json['tickets'] as List)
          .map((t) => Ticket.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Railway information
class Railway {
  final String code;

  const Railway({required this.code});

  factory Railway.fromJson(Map<String, dynamic> json) {
    return Railway(code: json['code'] as String);
  }
}

/// Station information
class Station {
  final String code;
  final String name;
  final String localName;
  final String helpUrl;

  const Station({
    required this.code,
    required this.name,
    required this.localName,
    required this.helpUrl,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      code: json['code'] as String,
      name: json['name'] as String,
      localName: json['local_name'] as String,
      helpUrl: json['help_url'] as String,
    );
  }
}

/// Price information
class Price {
  final String currency;
  final int cents;

  const Price({required this.currency, required this.cents});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      currency: json['currency'] as String,
      cents: json['cents'] as int,
    );
  }
}

/// Passenger response information
class PassengerResponse {
  final String id;
  final String firstName;
  final String lastName;
  final String birthdate;
  final String email;
  final String phone;
  final String gender;

  const PassengerResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthdate,
    required this.email,
    required this.phone,
    required this.gender,
  });

  factory PassengerResponse.fromJson(Map<String, dynamic> json) {
    return PassengerResponse(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      birthdate: json['birthdate'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      gender: json['gender'] as String,
    );
  }
}

/// Ticket information
class Ticket {
  final String id;
  final Station from;
  final Station to;

  const Ticket({
    required this.id,
    required this.from,
    required this.to,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      from: Station.fromJson(json['from'] as Map<String, dynamic>),
      to: Station.fromJson(json['to'] as Map<String, dynamic>),
    );
  }
}
