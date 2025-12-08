import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahana/features/requests/screens/request_detail_screen.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle foreground notification tap
        if (response.payload != null) {
          _handleMessageInteraction(response.payload!);
        }
      },
    );

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // Handle Background Notification Taps
    setupInteractedMessage();

    // Save Token
    await saveToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      _handleRemoteMessageInteraction(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleRemoteMessageInteraction,
    );
  }

  void _handleRemoteMessageInteraction(RemoteMessage message) async {
    if (message.data['type'] == 'request') {
      final requestId = message.data['id'];
      if (requestId != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('requests')
              .doc(requestId)
              .get();

          if (doc.exists) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => RequestDetailScreen(
                  requestId: requestId,
                  requestData: doc.data() as Map<String, dynamic>,
                ),
              ),
            );
          }
        } catch (e) {
          print("Error fetching request details: $e");
        }
      }
    }
  }

  void _handleMessageInteraction(String payload) {
    // Handle local notification payload
    print("Local Notification tapped with payload: $payload");
  }

  Future<void> saveToken() => _saveTokenToDatabase();

  Future<void> _saveTokenToDatabase([String? token]) async {
    String? fcmToken = token ?? await _firebaseMessaging.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && fcmToken != null) {
      // Save to a separate collection 'user_tokens'
      await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(user.uid)
          .set({
            'fcmToken': fcmToken,
            'updatedAt': FieldValue.serverTimestamp(),
            'platform': Theme.of(
              navigatorKey.currentContext ?? navigatorKey.currentState!.context,
            ).platform.toString(),
          }, SetOptions(merge: true));
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
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(), // Pass data as payload
      );
    }
  }
}
