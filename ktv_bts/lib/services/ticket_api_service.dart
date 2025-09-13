import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket_request.dart';

/// Service for calling external ticket API
class TicketApiService {
  // Actual endpoint
  static const String _apiBaseUrl = 'https://ezzn8n.zeabur.app';
  static const String _ticketEndpoint = '/webhook-test/order-ticket';

  /// Submit ticket request to external API
  Future<TicketApiResponse> submitTicketRequest({
    required String paymentRefno,
    required TicketRequest ticketRequest,
  }) async {
    try {
      final requestBody = {
        'PaymentRefno': paymentRefno,
        'RecipientEmail': ticketRequest.recipientEmail,
        'TotalTickets': ticketRequest.totalTickets,
        'TicketInfo': ticketRequest.ticketInfo.map((ticket) => ticket.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl$_ticketEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final errorCode = responseData['ErrorCode'] as int? ?? -1;
        final errorMessage = responseData['ErrorMessage'] as String? ?? 'Unknown error';
        
        if (errorCode == 0) {
          return TicketApiResponse.success(
            message: 'Ticket request submitted successfully',
            data: responseData,
            errorCode: errorCode,
          );
        } else {
          return TicketApiResponse.failure(
            errorMessage: errorMessage,
            statusCode: response.statusCode,
            errorCode: errorCode,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        final errorCode = errorData['ErrorCode'] as int? ?? -1;
        final errorMessage = errorData['ErrorMessage'] as String? ?? 'Failed to submit ticket request';
        
        return TicketApiResponse.failure(
          errorMessage: errorMessage,
          statusCode: response.statusCode,
          errorCode: errorCode,
        );
      }
    } catch (e) {
      return TicketApiResponse.failure(
        errorMessage: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

/// Response model for ticket API calls
class TicketApiResponse {
  final bool success;
  final String? message;
  final String? errorMessage;
  final int? statusCode;
  final Map<String, dynamic>? data;
  final int? errorCode; // New field for ErrorCode from API response

  const TicketApiResponse({
    required this.success,
    this.message,
    this.errorMessage,
    this.statusCode,
    this.data,
    this.errorCode,
  });

  /// Create successful response
  factory TicketApiResponse.success({
    required String message,
    Map<String, dynamic>? data,
    int? errorCode,
  }) {
    return TicketApiResponse(
      success: true,
      message: message,
      data: data,
      errorCode: errorCode,
    );
  }

  /// Create failed response
  factory TicketApiResponse.failure({
    required String errorMessage,
    int? statusCode,
    int? errorCode,
  }) {
    return TicketApiResponse(
      success: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'TicketApiResponse(success: $success, message: $message, errorMessage: $errorMessage, statusCode: $statusCode, errorCode: $errorCode)';
  }
}
