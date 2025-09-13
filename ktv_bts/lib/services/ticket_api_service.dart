import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket_request.dart';

/// Service for calling external ticket API
class TicketApiService {
  // Actual endpoint
  static const String _apiBaseUrl = 'https://ezzn8n.zeabur.app';
  static const String _ticketEndpoint = '/webhook/order-ticket';

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

      final requestUrl = '$_apiBaseUrl$_ticketEndpoint';
      final requestJson = json.encode(requestBody);
      
      // Log request details
      print('🚀 [API REQUEST]');
      print('📍 URL: $requestUrl');
      print('📤 Method: POST');
      print('📋 Headers: {"Content-Type": "application/json", "Accept": "application/json"}');
      print('📦 Request Body:');
      print('   ${requestJson.replaceAll(',', ',\n   ')}');
      print('');

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestJson,
      );

      // Log response details
      print('📥 [API RESPONSE]');
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Headers: ${response.headers}');
      print('📦 Response Body:');
      print('   ${response.body.replaceAll(',', ',\n   ')}');
      print('');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final errorCode = responseData['ErrorCode'] as int? ?? -1;
        final errorMessage = responseData['ErrorMessage'] as String? ?? 'Unknown error';
        
        if (errorCode == 0) {
          print('✅ [API SUCCESS]');
          print('🎉 Ticket request submitted successfully');
          print('📊 ErrorCode: $errorCode');
          print('');
          
          return TicketApiResponse.success(
            message: 'Ticket request submitted successfully',
            data: responseData,
            errorCode: errorCode,
          );
        } else {
          print('⚠️ [API BUSINESS ERROR]');
          print('❌ ErrorCode: $errorCode');
          print('📝 ErrorMessage: $errorMessage');
          print('📊 StatusCode: ${response.statusCode}');
          print('');
          
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
        
        print('🚫 [API HTTP ERROR]');
        print('📊 StatusCode: ${response.statusCode}');
        print('❌ ErrorCode: $errorCode');
        print('📝 ErrorMessage: $errorMessage');
        print('');
        
        return TicketApiResponse.failure(
          errorMessage: errorMessage,
          statusCode: response.statusCode,
          errorCode: errorCode,
        );
      }
    } catch (e) {
      // Log error details
      print('❌ [API ERROR]');
      print('🔥 Error Type: ${e.runtimeType}');
      print('📝 Error Message: ${e.toString()}');
      print('📍 URL: $_apiBaseUrl$_ticketEndpoint');
      print('');
      
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
