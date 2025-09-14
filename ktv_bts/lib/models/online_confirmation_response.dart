/// Model for G2Rail online_confirmations API response
class OnlineConfirmationResponse {
  final String id;
  final Order order;
  final Price paymentPrice;
  final Price chargingPrice;
  final Price rebateAmount;
  final String confirmAgain;
  final List<TicketCheckIn> ticketCheckIns;

  const OnlineConfirmationResponse({
    required this.id,
    required this.order,
    required this.paymentPrice,
    required this.chargingPrice,
    required this.rebateAmount,
    required this.confirmAgain,
    required this.ticketCheckIns,
  });

  /// Create from JSON
  factory OnlineConfirmationResponse.fromJson(Map<String, dynamic> json) {
    return OnlineConfirmationResponse(
      id: json['id'] as String,
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      paymentPrice: Price.fromJson(json['payment_price'] as Map<String, dynamic>),
      chargingPrice: Price.fromJson(json['charging_price'] as Map<String, dynamic>),
      rebateAmount: Price.fromJson(json['rebate_amount'] as Map<String, dynamic>),
      confirmAgain: json['confirm_again'] as String,
      ticketCheckIns: json['ticket_check_ins'] != null 
          ? (json['ticket_check_ins'] as List)
              .map((tci) => TicketCheckIn.fromJson(tci as Map<String, dynamic>))
              .toList()
          : <TicketCheckIn>[],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order.toJson(),
      'payment_price': paymentPrice.toJson(),
      'charging_price': chargingPrice.toJson(),
      'rebate_amount': rebateAmount.toJson(),
      'confirm_again': confirmAgain,
      'ticket_check_ins': ticketCheckIns.map((tci) => tci.toJson()).toList(),
    };
  }
}

/// Order information in confirmation response
class Order {
  final String id;
  final String pnr;
  final Railway railway;
  final Station from;
  final Station to;
  final String departure;
  final List<PassengerResponse> passengers;
  final List<Ticket> tickets;
  final List<Reservation> reservations;

  const Order({
    required this.id,
    required this.pnr,
    required this.railway,
    required this.from,
    required this.to,
    required this.departure,
    required this.passengers,
    required this.tickets,
    required this.reservations,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      pnr: json['PNR'] as String,
      railway: Railway.fromJson(json['railway'] as Map<String, dynamic>),
      from: Station.fromJson(json['from'] as Map<String, dynamic>),
      to: Station.fromJson(json['to'] as Map<String, dynamic>),
      departure: json['departure'] as String,
      passengers: json['passengers'] != null
          ? (json['passengers'] as List)
              .map((p) => PassengerResponse.fromJson(p as Map<String, dynamic>))
              .toList()
          : <PassengerResponse>[],
      tickets: json['tickets'] != null
          ? (json['tickets'] as List)
              .map((t) => Ticket.fromJson(t as Map<String, dynamic>))
              .toList()
          : <Ticket>[],
      reservations: json['reservations'] != null
          ? (json['reservations'] as List)
              .map((r) => Reservation.fromJson(r as Map<String, dynamic>))
              .toList()
          : <Reservation>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'PNR': pnr,
      'railway': railway.toJson(),
      'from': from.toJson(),
      'to': to.toJson(),
      'departure': departure,
      'passengers': passengers.map((p) => p.toJson()).toList(),
      'tickets': tickets.map((t) => t.toJson()).toList(),
      'reservations': reservations.map((r) => r.toJson()).toList(),
    };
  }
}

/// Railway information
class Railway {
  final String code;

  const Railway({required this.code});

  factory Railway.fromJson(Map<String, dynamic> json) {
    return Railway(code: json['code'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'code': code};
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
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      localName: json['local_name'] as String? ?? '',
      helpUrl: json['help_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'local_name': localName,
      'help_url': helpUrl,
    };
  }
}

/// Price information
class Price {
  final String currency;
  final int cents;

  const Price({required this.currency, required this.cents});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      currency: json['currency'] as String? ?? 'EUR',
      cents: json['cents'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'cents': cents,
    };
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
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      birthdate: json['birthdate'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birthdate': birthdate,
      'email': email,
      'phone': phone,
      'gender': gender,
    };
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
      id: json['id'] as String? ?? '',
      from: Station.fromJson(json['from'] as Map<String, dynamic>? ?? {}),
      to: Station.fromJson(json['to'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from.toJson(),
      'to': to.toJson(),
    };
  }
}

/// Reservation information
class Reservation {
  final String trainName;
  final String car;
  final String seat;

  const Reservation({
    required this.trainName,
    required this.car,
    required this.seat,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      trainName: json['train_name'] as String? ?? '',
      car: json['car'] as String? ?? '',
      seat: json['seat'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'train_name': trainName,
      'car': car,
      'seat': seat,
    };
  }
}

/// Ticket check-in information
class TicketCheckIn {
  final String checkInUrl;
  final String earliestCheckInTimestamp;
  final String latestCheckInTimestamp;

  const TicketCheckIn({
    required this.checkInUrl,
    required this.earliestCheckInTimestamp,
    required this.latestCheckInTimestamp,
  });

  factory TicketCheckIn.fromJson(Map<String, dynamic> json) {
    return TicketCheckIn(
      checkInUrl: json['check_in_url'] as String? ?? '',
      earliestCheckInTimestamp: json['earliest_check_in_timestamp'] as String? ?? '',
      latestCheckInTimestamp: json['latest_check_in_timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'check_in_url': checkInUrl,
      'earliest_check_in_timestamp': earliestCheckInTimestamp,
      'latest_check_in_timestamp': latestCheckInTimestamp,
    };
  }
}
