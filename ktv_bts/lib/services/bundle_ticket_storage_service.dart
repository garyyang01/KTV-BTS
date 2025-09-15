import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bundle_ticket.dart';

/// Bundle Ticket Storage Service
/// Handles storage and retrieval of bundle tickets
class BundleTicketStorageService {
  static const String _bundleTicketsKey = 'bundle_tickets';

  /// Save a bundle ticket
  static Future<void> saveBundleTicket(BundleTicket ticket) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingTickets = await getAllBundleTickets();
      existingTickets.add(ticket);
      
      final ticketsJson = existingTickets.map((t) => t.toJson()).toList();
      await prefs.setString(_bundleTicketsKey, json.encode(ticketsJson));
      
      print('✅ Bundle ticket saved: ${ticket.id}');
    } catch (e) {
      print('❌ Failed to save bundle ticket: $e');
      rethrow;
    }
  }

  /// Get all bundle tickets
  static Future<List<BundleTicket>> getAllBundleTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ticketsJson = prefs.getString(_bundleTicketsKey);
      
      if (ticketsJson == null) {
        return [];
      }
      
      final List<dynamic> ticketsList = json.decode(ticketsJson);
      return ticketsList.map((t) => BundleTicket.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      print('❌ Failed to load bundle tickets: $e');
      return [];
    }
  }

  /// Get bundle ticket by ID
  static Future<BundleTicket?> getBundleTicket(String id) async {
    try {
      final tickets = await getAllBundleTickets();
      return tickets.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete bundle ticket
  static Future<void> deleteBundleTicket(String id) async {
    try {
      final tickets = await getAllBundleTickets();
      tickets.removeWhere((t) => t.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final ticketsJson = tickets.map((t) => t.toJson()).toList();
      await prefs.setString(_bundleTicketsKey, json.encode(ticketsJson));
      
      print('✅ Bundle ticket deleted: $id');
    } catch (e) {
      print('❌ Failed to delete bundle ticket: $e');
      rethrow;
    }
  }

  /// Clear all bundle tickets
  static Future<void> clearAllBundleTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bundleTicketsKey);
      print('✅ All bundle tickets cleared');
    } catch (e) {
      print('❌ Failed to clear bundle tickets: $e');
      rethrow;
    }
  }
}
