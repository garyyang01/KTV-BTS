import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bundle_info.dart';

/// Bundle Service for calling n8n webhook API
class BundleService {
  static const String _baseUrl = 'https://ezzn8n.zeabur.app/webhook/get-bundle-ticket';
  
  /// Get all bundles from API
  static Future<List<BundleInfo>> getBundles() async {
    try {
      print('Calling Bundle API: $_baseUrl');
      
      // Make HTTP POST request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({}), // Empty JSON body for POST request
      );
      
      print('Bundle API Response Status: ${response.statusCode}');
      print('Bundle API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Parse JSON response
        final List<dynamic> jsonList = json.decode(response.body);
        
        // Convert to BundleInfo objects
        final List<BundleInfo> bundles = jsonList.map((json) {
          return BundleInfo.fromApiJson(json);
        }).toList();
        
        print('Successfully loaded ${bundles.length} bundles');
        return bundles;
      } else {
        print('Bundle API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load bundles: ${response.statusCode}');
      }
    } catch (e) {
      print('Bundle Service Error: $e');
      throw Exception('Failed to load bundles: $e');
    }
  }
  
  /// Test the bundle service
  static Future<List<BundleInfo>> testBundles() async {
    return await getBundles();
  }
}
