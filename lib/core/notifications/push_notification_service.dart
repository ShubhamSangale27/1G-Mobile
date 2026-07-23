import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/devices/data/device_token_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background data-only messages can be handled here if needed.
}

typedef NotificationTapHandler = void Function(Map<String, String> data);

class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'guntha_push';
  String? _currentToken;
  NotificationTapHandler? _onTap;
  Map<String, String>? _pendingTapData;

  Future<void> initialize({required NotificationTapHandler onTap}) async {
    _onTap = onTap;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _dispatchTap(_decodePayload(payload));
        }
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          '1Guntha Notifications',
          description: 'Property updates and announcements',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _pendingTapData = _extractData(initial);
    }

    _messaging.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await syncTokenWithBackend();
    });
  }

  Map<String, String>? consumePendingTap() {
    final data = _pendingTapData;
    _pendingTapData = null;
    return data;
  }

  Future<void> syncTokenWithBackend() async {
    if (!_ref.read(authControllerProvider).isLoggedIn) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _currentToken = token;
      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      await _ref.read(deviceTokenRepositoryProvider).registerToken(
            token: token,
            platform: platform,
          );
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      final token = _currentToken ?? await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _ref.read(deviceTokenRepositoryProvider).deactivateToken(token);
        await _messaging.deleteToken();
      }
    } catch (e) {
      debugPrint('FCM token unregister failed: $e');
    } finally {
      _currentToken = null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = _extractData(message);
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      '1Guntha Notifications',
      channelDescription: 'Property updates and announcements',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: _encodePayload(data),
    );
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _dispatchTap(_extractData(message));
  }

  void _dispatchTap(Map<String, String> data) {
    if (data.isEmpty) return;
    _onTap?.call(data);
  }

  Map<String, String> _extractData(RemoteMessage message) {
    final data = Map<String, String>.from(message.data);
    if (!data.containsKey('linkUrl') && message.notification != null) {
      // Notification payload only — still deliver tap to home.
    }
    return data;
  }

  String _encodePayload(Map<String, String> data) => jsonEncode(data);

  Map<String, String> _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', '$value'));
      }
    } catch (_) {}
    return {};
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
