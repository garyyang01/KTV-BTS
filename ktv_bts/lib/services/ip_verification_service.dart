import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

/// Service for verifying user IP addresses before allowing payment
class IpVerificationService {
  static const String _verificationEndpoint = 'https://ezzn8n.zeabur.app/webhook/api/check-attempt';

  /// Check if the user's IP address is authorized to proceed with payment
  /// Returns true if authorized, false if blocked
  Future<bool> verifyUserIp() async {
    try {
      // Get user's IP address
      final userIp = await _getUserIp();

      print('🔒 Verifying IP address: $userIp');

      // Send verification request
      final response = await http.post(
        Uri.parse(_verificationEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'IP': userIp,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final errorCode = responseData['errorCode'] ?? 0;

        print('🔒 IP verification response - errorCode: $errorCode');

        // If errorCode != 0, the user is not authorized
        if (errorCode != 0) {
          print('⛔ IP verification failed - User blocked with errorCode: $errorCode');
          return false;
        }

        print('✅ IP verification successful - User authorized');
        return true;
      } else {
        // If the API returns non-200 status, we'll allow the user to proceed
        // to avoid blocking legitimate users due to API issues
        print('⚠️ IP verification API returned status ${response.statusCode} - Allowing user to proceed');
        return true;
      }
    } catch (e) {
      // In case of any error (network issues, etc.), we'll allow the user to proceed
      // to avoid blocking legitimate users due to technical issues
      print('⚠️ IP verification error: $e - Allowing user to proceed');
      return true;
    }
  }

  /// Get the user's IP address
  /// This is a simplified implementation - in production, you might need to
  /// handle proxies, load balancers, or use a third-party IP detection service
  Future<String> _getUserIp() async {
    try {
      // Try to get public IP from an external service
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=text'),
        headers: {
          'Accept': 'text/plain',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      print('⚠️ Could not get IP from ipify: $e');
    }

    // Fallback: try alternative IP service
    try {
      final response = await http.get(
        Uri.parse('https://checkip.amazonaws.com/'),
        headers: {
          'Accept': 'text/plain',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      print('⚠️ Could not get IP from AWS: $e');
    }

    // Last resort: return a default IP (this should rarely happen)
    return '0.0.0.0';
  }

  /// Get error message for display to user when verification fails
  String getBlockedUserMessage() {
    return '''
Access Denied

Your access to this service has been restricted.
This may be due to one of the following reasons:

1. Multiple failed payment attempts
2. Suspicious activity detected
3. Geographic restrictions
4. Account security concerns

If you believe this is an error, please contact our support team.
''';
  }
}