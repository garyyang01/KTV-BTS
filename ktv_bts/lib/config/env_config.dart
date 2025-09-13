import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration class for managing environment variables
class EnvConfig {
  static bool _isInitialized = false;

  /// Initialize environment variables
  static Future<void> initialize() async {
    if (!_isInitialized) {
      await dotenv.load(fileName: ".env");
      _isInitialized = true;
    }
  }

  /// Get Stripe public key
  static String get stripePublicKey {
    final key = dotenv.env['STRIPE_PUBLIC_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('STRIPE_PUBLIC_KEY not found in environment variables');
    }
    return key;
  }

  /// Get Stripe secret key
  static String get stripeSecretKey {
    final key = dotenv.env['STRIPE_SECRET_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('STRIPE_SECRET_KEY not found in environment variables');
    }
    return key;
  }

  /// Get environment type
  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  /// Check if running in development mode
  static bool get isDevelopment {
    return environment.toLowerCase() == 'development';
  }

  /// Check if running in production mode
  static bool get isProduction {
    return environment.toLowerCase() == 'production';
  }

  /// Get all environment variables (for debugging)
  static Map<String, String> getAllEnvVars() {
    return Map.from(dotenv.env);
  }

  /// Validate required environment variables
  static void validateRequiredVars() {
    final requiredVars = ['STRIPE_PUBLIC_KEY', 'STRIPE_SECRET_KEY'];
    
    for (final varName in requiredVars) {
      final value = dotenv.env[varName];
      if (value == null || value.isEmpty) {
        throw Exception('Required environment variable $varName is missing or empty');
      }
    }
  }
}
