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
///1. Khởi tạo Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('!!!!!!!! [NotificationService] Người dùng đã được cấp quyền !!!!!!!!');
    } else {
      print('!!!!!!!! [NotificationService] Người dùng đã từ chối quyền !!!!!!!!');
      return; 
    }

    print('!!!!!!!! [NotificationService] kIsWeb: $kIsWeb !!!!!!!!');

    /// 2. Thiết lập thông báo cục bộ (cho ứng dụng chạy nền)
    if (!kIsWeb) {
      print('!!!!!!!! [NotificationService] Initializing Local Notifications... !!!!!!!!');
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      try {
        await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
        print('!!!!!!!! [NotificationService] Local Notifications Initialized. !!!!!!!!');

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
        print('!!!!!!!! [NotificationService] Notification Channel Created. !!!!!!!!');

      } catch (e) {
        print('!!!!!!!! [NotificationService] ❌ Local Notifications Init Failed: $e !!!!!!!!');
      }
    }

    /// 3. Xử lý các thông báo nền trước (FCM)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (!kIsWeb && notification != null && android != null) {
        _showLocalNotification(
          title: message.notification?.title ?? 'MediHouse',
          body: message.notification?.body ?? '',
        );
      }
    });

    /// 4. Nhận và lưu mã thông báo (Hãy thử ngay lập tức)
    print('!!!!!!!! [NotificationService] calling _saveTokenToSupabase()... !!!!!!!!');
    await _saveTokenToSupabase();

    /// 5. Theo dõi để làm mới mã thông báo
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(token: newToken);
    });

    /// 6. Theo dõi sự thay đổi trạng thái xác thực (Điều này rất quan trọng để lưu mã thông báo sau khi đăng nhập)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      print('!!!!!!!! [NotificationService] Auth State Change: ${data.event} !!!!!!!!');
      if (data.session != null && (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.initialSession)) {
        print('!!!!!!!! [NotificationService] User is signed in. Attempting to save token... !!!!!!!!');
        _saveTokenToSupabase();
        _listenToDatabaseNotifications();
      }
    });
  }

  void _listenToDatabaseNotifications() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    print('!!!!!!!! [NotificationService] Subscribing to Realtime INSERT events for user ${user.id} !!!!!!!!');

    Supabase.instance.client.channel('public:notifications:${user.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (payload) {
          print('!!!!!!!! [NotificationService] Realtime Event Received! Payload: ${payload.newRecord} !!!!!!!!');
          final newRecord = payload.newRecord;
          _showLocalNotification(
            title: newRecord['title'] ?? 'MediHouse',
            body: newRecord['body'] ?? 'Bạn có thông báo mới',
            payload: newRecord['id'],
          );
        },
      )
      .subscribe();
  }

  Future<void> _showLocalNotification({required String title, required String body, String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'high_importance_channel', 'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
            
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond, title, body, platformChannelSpecifics,
        payload: payload);
  }

  Future<void> _saveTokenToSupabase({String? token}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[NotificationService] Skipping FCM token save: No user logged in yet.');
      return;
    }

    debugPrint('[NotificationService] Found Logged In User: ${user.id}');

    try {
      if (token == null) {
        debugPrint('[NotificationService] Retrieving FCM Token from Firebase...');
        token = await _firebaseMessaging.getToken(
            );
      }
    } catch (e) {
      debugPrint('[NotificationService] Error getting token from Firebase: $e');
      return;
    }
    
    if (token == null) {
        debugPrint('[NotificationService] Failed to get FCM Token (it is null).');
        return;
    }

    debugPrint('[NotificationService] FCM Token retrieved: ${token.substring(0, 5)}... (truncated)');

    String deviceType = 'unknown';
    if (kIsWeb) {
      deviceType = 'web';
    } else if (Platform.isAndroid) {
      deviceType = 'android';
    } else if (Platform.isIOS) {
      deviceType = 'ios';
    }

    try {
      debugPrint('[NotificationService] Saving to Supabase table "user_fcm_tokens"...');
      await Supabase.instance.client.from('user_fcm_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'device_type': deviceType,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, token', 
      );
      debugPrint('[NotificationService] ✅ FCM Token saved to Supabase successfully!');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error saving FCM Token to Supabase: $e');
      debugPrint('[NotificationService] 💡 Hint: Check if table "user_fcm_tokens" exists and RLS policies allow INSERT.');
    }
  }
}
