import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI Service for calling n8n webhook API
class AIService {
  static const String _baseUrl = 'https://ezzn8n.zeabur.app/webhook/AITripAssistant';
  
  /// Call n8n AI API with user prompt
  static Future<String> callAIAssistant(String prompt) async {
    try {
      // Encode the prompt for URL
      final encodedPrompt = Uri.encodeComponent(prompt);
      final url = '$_baseUrl?Prompt=$encodedPrompt';
      
      print('Calling AI API: $url');
      
      // Make HTTP GET request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('AI API Response Status: ${response.statusCode}');
      print('AI API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Extract output from response
        final String output = jsonResponse['output'] ?? 'Sorry, I could not process your request.';
        
        return output;
      } else {
        print('AI API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, there was an error processing your request. Please try again.';
      }
    } catch (e) {
      print('AI Service Error: $e');
      return 'Sorry, there was a connection error. Please check your internet connection and try again.';
    }
  }
  
  /// Test the AI service with a sample prompt
  static Future<String> testAI() async {
    return await callAIAssistant('Who are you?');
  }
}
