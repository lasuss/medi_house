import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return; 
    }

    // 2. Setup Local Notifications (for foreground)
    // On Web, local notifications are less common or handled by SW. 
    // We can conditionally init for Android/iOS.
    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    }

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // On Web, notification is null usually if window is in focus, or handled by browser.
      // On Android, we show local notification.
      if (!kIsWeb && notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // channelId
              'High Importance Notifications', // channelName
              channelDescription:
                  'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 4. Get and Save Token
    await _saveTokenToSupabase();

    // 5. Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(token: newToken);
    });
  }

  Future<void> _saveTokenToSupabase({String? token}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      token ??= await _firebaseMessaging.getToken(
        // VAPID Key is required for Web if you want it to work efficiently, 
        // otherwise it uses default.
        // vapidKey: 'YOUR_VAPID_KEY'
      );
    } catch (e) {
      debugPrint('Error getting token: $e');
      return;
    }
    
    if (token == null) return;

    String deviceType = 'unknown';
    if (kIsWeb) {
      deviceType = 'web';
    } else if (Platform.isAndroid) {
      deviceType = 'android';
    } else if (Platform.isIOS) {
      deviceType = 'ios';
    }

    try {
      await Supabase.instance.client.from('user_fcm_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'device_type': deviceType,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, token', 
      );
      debugPrint('FCM Token saved to Supabase');
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }
}
