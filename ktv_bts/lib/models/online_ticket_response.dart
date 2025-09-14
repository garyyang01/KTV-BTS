/// Model for G2Rail online_tickets API response
class OnlineTicketResponse {
  final List<TicketFile> tickets;

  const OnlineTicketResponse({
    required this.tickets,
  });

  /// Create from JSON
  factory OnlineTicketResponse.fromJson(List<dynamic> json) {
    return OnlineTicketResponse(
      tickets: json.map((ticket) => TicketFile.fromJson(ticket as Map<String, dynamic>? ?? {})).toList(),
    );
  }

  /// Convert to JSON
  List<Map<String, dynamic>> toJson() {
    return tickets.map((ticket) => ticket.toJson()).toList();
  }
}

/// Individual ticket file information
class TicketFile {
  final String file;
  final String kind;

  const TicketFile({
    required this.file,
    required this.kind,
  });

  /// Create from JSON
  factory TicketFile.fromJson(Map<String, dynamic> json) {
    return TicketFile(
      file: json['file'] as String? ?? '',
      kind: json['kind'] as String? ?? json['type'] as String? ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'kind': kind,
    };
  }

  /// Check if this is a PDF ticket
  bool get isPdfTicket => kind == 'pdf_ticket';

  /// Check if this is a mobile ticket
  bool get isMobileTicket => kind == 'mobile_ticket';

  /// Get ticket type display name
  String get ticketTypeDisplayName {
    switch (kind) {
      case 'pdf_ticket':
        return 'PDF 票券';
      case 'mobile_ticket':
        return '手機票券';
      default:
        return '未知票券類型';
    }
  }
}
