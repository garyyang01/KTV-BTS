import 'ticket_info.dart';

/// New API spec for ticket request
class TicketRequest {
  final String recipientEmail;
  final int totalTickets;
  final List<TicketInfo> ticketInfo;

  const TicketRequest({
    required this.recipientEmail,
    required this.totalTickets,
    required this.ticketInfo,
  });

  /// Calculate total amount for all tickets
  double get totalAmount {
    return ticketInfo.fold(0.0, (sum, ticket) => sum + ticket.price);
  }

  /// Get all adult tickets
  List<TicketInfo> get adultTickets {
    return ticketInfo.where((ticket) => ticket.isAdult).toList();
  }

  /// Get all child tickets
  List<TicketInfo> get childTickets {
    return ticketInfo.where((ticket) => !ticket.isAdult).toList();
  }

  /// Convert to JSON according to new API spec
  Map<String, dynamic> toJson() {
    return {
      'RecipientEmail': recipientEmail,
      'TotalTickets': totalTickets,
      'TicketInfo': ticketInfo.map((ticket) => ticket.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory TicketRequest.fromJson(Map<String, dynamic> json) {
    return TicketRequest(
      recipientEmail: json['RecipientEmail'] as String,
      totalTickets: json['TotalTickets'] as int,
      ticketInfo: (json['TicketInfo'] as List)
          .map((ticketJson) => TicketInfo.fromJson(ticketJson as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'TicketRequest(recipientEmail: $recipientEmail, totalTickets: $totalTickets, ticketInfo: $ticketInfo)';
  }
}
