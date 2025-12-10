import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahana/features/chat/screens/chat_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static BuildContext? _context;

  static void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize Local Notifications (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Note: For iOS, you need DarwinInitializationSettings
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Save Token
    await _saveTokenToDatabase();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap
    print('Notification tapped: ${response.payload}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    if (_context == null) {
      print('Context not set, cannot navigate');
      return;
    }

    if (type == 'chat') {
      // Navigate to chat screen
      final requestId = data['requestId'];
      final senderId = data['senderId'];

      if (senderId != null) {
        _navigateToChat(_context!, requestId, senderId);
      }
    } else if (data['requestId'] != null) {
      // Navigate to request detail screen
      _navigateToRequestDetail(_context!, data['requestId']);
    }
  }

  Future<void> _navigateToChat(
    BuildContext context,
    String? requestId,
    String senderId,
  ) async {
    try {
      // Get sender details
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      final senderName = senderDoc.data()?['name'] ?? 'User';

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              requestId: requestId,
              otherUserName: senderName,
              otherUserId: senderId,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to chat: $e');
    }
  }

  Future<void> _navigateToRequestDetail(
    BuildContext context,
    String requestId,
  ) async {
    // You can implement this similar to chat navigation
    print('Navigate to request detail: $requestId');
  }

  Future<void> _saveTokenToDatabase([String? token]) async {
    String? fcmToken = token ?? await _firebaseMessaging.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && fcmToken != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users_tokens')
            .doc(user.uid)
            .set({
              'userId': user.uid,
              'fcmToken': fcmToken,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        print('FCM Token saved to users_tokens: $fcmToken');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
