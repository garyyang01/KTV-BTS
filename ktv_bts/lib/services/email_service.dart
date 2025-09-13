import 'dart:async';
import 'dart:developer';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;

  // Email 設定 - 請替換為實際的 email 設定
  static const String _bossEmail = 'baluce@gmail.com';
  static const String _appEmail = 'e1z2r3a4@gmail.com';
  static const String _appPassword = 'okxh irzp zkkz pddo';
  static const String _imapHost = 'imap.gmail.com';

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  Future<bool> sendTicketRequestToBoss({
    required String userName,
    required bool isAdult,
    required String destination,
    required String orderId,
    required DateTime visitDateTime,
    String? recipientEmail,
    int? totalTickets,
    List<Map<String, dynamic>>? ticketInfo,
  }) async {
    try {
      log('開始寄信流程...');
      log('收件人: $_bossEmail');
      log('寄件人: $_appEmail');

      final smtpServer = gmail(_appEmail, _appPassword);
      log('SMTP 伺服器設定完成');

      final message = mailer.Message()
        ..from = mailer.Address(_appEmail, 'KTV-BTS App')
        ..recipients.add(_bossEmail)
        ..subject = 'Neuschwanstein Castle Ticket Application - Order ID: $orderId'
        ..html = _generateEmailContent(
          orderId: orderId,
          userName: userName,
          isAdult: isAdult,
          destination: destination,
          visitDateTime: visitDateTime,
          recipientEmail: recipientEmail,
          totalTickets: totalTickets,
          ticketInfo: ticketInfo,
        );

      log('郵件內容準備完成，開始發送...');
      final sendReport = await mailer.send(message, smtpServer);
      log('Email sent successfully: ${sendReport.toString()}');

      // 開始輪詢
      startPollingForReply(orderId);

      return true;
    } catch (e) {
      log('Error sending email: $e');
      log('Error type: ${e.runtimeType}');
      if (e is Exception) {
        log('Exception details: ${e.toString()}');
      }
      return false;
    }
  }

  /// Generate email content based on new API spec
  String _generateEmailContent({
    required String orderId,
    required String userName,
    required bool isAdult,
    required String destination,
    required DateTime visitDateTime,
    String? recipientEmail,
    int? totalTickets,
    List<Map<String, dynamic>>? ticketInfo,
  }) {
    // If new API format is provided, use it
    if (recipientEmail != null && totalTickets != null && ticketInfo != null) {
      final ticketDetails = ticketInfo.map((ticket) {
        final familyName = ticket['FamilyName'] as String;
        final givenName = ticket['GivenName'] as String;
        final isAdultTicket = ticket['IsAdult'] as bool;
        final session = ticket['Session'] as String;
        final arrivalTime = ticket['ArrivalTime'] as String;
        final price = ticket['Prize'] as double;
        
        return '''
          <tr>
            <td>$familyName $givenName</td>
            <td>${isAdultTicket ? 'Adult' : 'Child'}</td>
            <td>$session</td>
            <td>$arrivalTime</td>
            <td>€$price</td>
          </tr>
        ''';
      }).join('');
      
      final totalAmount = ticketInfo.fold(0.0, (sum, ticket) => sum + (ticket['Prize'] as double));
      
      return '''
        <h2>Neuschwanstein Castle Ticket Application</h2>
        <p><strong>Order ID:</strong> $orderId</p>
        <p><strong>Recipient Email:</strong> $recipientEmail</p>
        <p><strong>Total Tickets:</strong> $totalTickets</p>
        <p><strong>Total Amount:</strong> €$totalAmount</p>
        <br>
        <h3>Ticket Details:</h3>
        <table border="1" style="border-collapse: collapse; width: 100%;">
          <tr style="background-color: #f2f2f2;">
            <th>Name</th>
            <th>Type</th>
            <th>Session</th>
            <th>Arrival Date</th>
            <th>Price</th>
          </tr>
          $ticketDetails
        </table>
        <br>
        <p><strong>Application Time:</strong> ${DateTime.now()}</p>
        <br>
        <p>Please review the application information and reply with ticket attachments.</p>
        <p>If you have any questions, please contact the applicant.</p>
      ''';
    }
    
    // Fallback to legacy format
    return '''
      <h2>Neuschwanstein Castle Ticket Application</h2>
      <p><strong>Order ID:</strong> $orderId</p>
      <p><strong>Name:</strong> $userName (must match passport)</p>
      <p><strong>Ticket Type:</strong> ${isAdult ? 'Adult Ticket' : 'Child Ticket'}</p>
      <p><strong>Session:</strong> $destination</p>
      <p><strong>Visit Date:</strong> ${visitDateTime.year}/${visitDateTime.month}/${visitDateTime.day}</p>
      <p><strong>Visit Time:</strong> ${visitDateTime.hour.toString().padLeft(2, '0')}:${visitDateTime.minute.toString().padLeft(2, '0')}</p>
      <p><strong>Application Time:</strong> ${DateTime.now()}</p>
      <br>
      <p>Please review the application information and reply with ticket attachments.</p>
      <p>If you have any questions, please contact the applicant.</p>
    ''';
  }

  void startPollingForReply(String orderId) {
    log('開始輪詢訂單: $orderId');

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      log('檢查回信...');

      final hasReply = await _checkForReply(orderId);
      if (hasReply) {
        timer.cancel();
        await _showNotification('門票已收到！', '您的新天鵝堡門票已經準備好了');
        log('收到回信，停止輪詢');
      }

      // 30分鐘後停止輪詢
      if (timer.tick > 60) {
        timer.cancel();
        log('輪詢超時，停止檢查');
      }
    });
  }

  Future<bool> _checkForReply(String orderId) async {
    try {
      final client = ImapClient(isLogEnabled: false);

      await client.connectToServer(_imapHost, 993, isSecure: true);
      await client.login(_appEmail, _appPassword);
      await client.selectInbox();

      // 簡單檢查最近的郵件
      final mailboxResult = await client.fetchRecentMessages(messageCount: 10);

      for (final message in mailboxResult.messages) {
        final subject = message.decodeSubject() ?? '';
        if (subject.contains(orderId)) {
          log('找到包含訂單編號的回信: $subject');
          await client.logout();
          return true;
        }
      }

      await client.logout();
      return false;
    } catch (e) {
      log('檢查回信時發生錯誤: $e');
      return false;
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ticket_channel',
      'Ticket Notifications',
      channelDescription: '門票相關通知',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}