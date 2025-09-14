import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/online_confirmation_response.dart';
import '../models/online_ticket_response.dart';

/// 火車票存儲服務
/// 使用 SharedPreferences 來存儲火車票數據
class TicketStorageService {
  static const String _ticketsKey = 'train_tickets';
  static const String _confirmationsKey = 'train_confirmations';

  /// 存儲火車票確認資訊
  static Future<void> saveTicketConfirmation({
    required String orderId,
    required OnlineConfirmationResponse confirmation,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final confirmations = await getTicketConfirmations();
      
      confirmations[orderId] = confirmation.toJson();
      
      await prefs.setString(_confirmationsKey, json.encode(confirmations));
      print('✅ 火車票確認資訊已保存: $orderId');
    } catch (e) {
      print('❌ 保存火車票確認資訊失敗: $e');
    }
  }

  /// 存儲火車票文件資訊
  static Future<void> saveTicketFiles({
    required String orderId,
    required OnlineTicketResponse tickets,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ticketFiles = await getAllTicketFiles();
      
      ticketFiles[orderId] = tickets.toJson();
      
      await prefs.setString(_ticketsKey, json.encode(ticketFiles));
      print('✅ 火車票文件資訊已保存: $orderId');
    } catch (e) {
      print('❌ 保存火車票文件資訊失敗: $e');
    }
  }

  /// 獲取所有火車票確認資訊
  static Future<Map<String, Map<String, dynamic>>> getTicketConfirmations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final confirmationsJson = prefs.getString(_confirmationsKey);
      
      if (confirmationsJson != null) {
        final confirmations = json.decode(confirmationsJson) as Map<String, dynamic>;
        return confirmations.map((key, value) => MapEntry(key, value as Map<String, dynamic>));
      }
      
      return {};
    } catch (e) {
      print('❌ 獲取火車票確認資訊失敗: $e');
      return {};
    }
  }

  /// 獲取所有火車票文件資訊
  static Future<Map<String, List<Map<String, dynamic>>>> getAllTicketFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ticketsJson = prefs.getString(_ticketsKey);
      
      if (ticketsJson != null) {
        final tickets = json.decode(ticketsJson) as Map<String, dynamic>;
        return tickets.map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)));
      }
      
      return {};
    } catch (e) {
      print('❌ 獲取火車票文件資訊失敗: $e');
      return {};
    }
  }

  /// 獲取特定訂單的確認資訊
  static Future<OnlineConfirmationResponse?> getTicketConfirmation(String orderId) async {
    try {
      final confirmations = await getTicketConfirmations();
      final confirmationData = confirmations[orderId];
      
      if (confirmationData != null) {
        return OnlineConfirmationResponse.fromJson(confirmationData);
      }
      
      return null;
    } catch (e) {
      print('❌ 獲取特定訂單確認資訊失敗: $e');
      return null;
    }
  }

  /// 獲取特定訂單的票券文件
  static Future<OnlineTicketResponse?> getTicketFiles(String orderId) async {
    try {
      final ticketFiles = await getAllTicketFiles();
      final filesData = ticketFiles[orderId];
      
      if (filesData != null) {
        return OnlineTicketResponse.fromJson(filesData);
      }
      
      return null;
    } catch (e) {
      print('❌ 獲取特定訂單票券文件失敗: $e');
      return null;
    }
  }

  /// 獲取所有已保存的訂單ID列表
  static Future<List<String>> getAllOrderIds() async {
    try {
      final confirmations = await getTicketConfirmations();
      return confirmations.keys.toList();
    } catch (e) {
      print('❌ 獲取訂單ID列表失敗: $e');
      return [];
    }
  }

  /// 刪除特定訂單的數據
  static Future<void> deleteTicketData(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final confirmations = await getTicketConfirmations();
      final ticketFiles = await getAllTicketFiles();
      
      confirmations.remove(orderId);
      ticketFiles.remove(orderId);
      
      await prefs.setString(_confirmationsKey, json.encode(confirmations));
      await prefs.setString(_ticketsKey, json.encode(ticketFiles));
      
      print('✅ 訂單數據已刪除: $orderId');
    } catch (e) {
      print('❌ 刪除訂單數據失敗: $e');
    }
  }

  /// 清空所有火車票數據
  static Future<void> clearAllTicketData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_confirmationsKey);
      await prefs.remove(_ticketsKey);
      print('✅ 所有火車票數據已清空');
    } catch (e) {
      print('❌ 清空火車票數據失敗: $e');
    }
  }
}
