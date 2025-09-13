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
        ..subject = '新天鵝堡門票申請 - 訂單編號: $orderId'
        ..html = '''
          <h2>新天鵝堡門票申請</h2>
          <p><strong>訂單編號:</strong> $orderId</p>
          <p><strong>姓名:</strong> $userName (與護照相同)</p>
          <p><strong>票種:</strong> ${isAdult ? '成人票' : '兒童票'}</p>
          <p><strong>場次:</strong> $destination</p>
          <p><strong>參觀日期:</strong> ${visitDateTime.year}/${visitDateTime.month}/${visitDateTime.day}</p>
          <p><strong>參觀時間:</strong> ${visitDateTime.hour.toString().padLeft(2, '0')}:${visitDateTime.minute.toString().padLeft(2, '0')}</p>
          <p><strong>申請時間:</strong> ${DateTime.now()}</p>
          <br>
          <p>請審核申請資訊並回覆門票附件。</p>
          <p>如有問題請聯繫申請人。</p>
        ''';

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