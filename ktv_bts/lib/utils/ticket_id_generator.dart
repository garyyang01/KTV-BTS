import 'dart:math';

/// Utility class for generating ticket IDs and time-related functions
class TicketIdGenerator {
  static const String _prefix = 'tickettrip_';
  static const int _randomLength = 16;
  
  /// Generate a random ticket ID with format: tickettrip_ + 16 random characters
  static String generateTicketId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    
    final randomString = String.fromCharCodes(
      Iterable.generate(
        _randomLength,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    
    return '$_prefix$randomString';
  }
  
  /// Generate multiple ticket IDs
  static List<String> generateTicketIds(int count) {
    return List.generate(count, (_) => generateTicketId());
  }
  
  /// Determine session (Morning/Afternoon) based on 24-hour time
  static String getSessionFromTime(DateTime time) {
    final hour = time.hour;
    // Morning: 00:00 - 11:59, Afternoon: 12:00 - 23:59
    return hour < 12 ? 'Morning' : 'Afternoon';
  }
}
