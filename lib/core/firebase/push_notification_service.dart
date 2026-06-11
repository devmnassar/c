import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/firebase_options.dart';

const String _kAndroidNotificationChannelId = 'gaseel_general_notifications';
const String _kAndroidNotificationChannelName = 'General Notifications';
const String _kAndroidNotificationChannelDescription =
    'General app notifications for Gaseel Courier.';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final payload = AppNotificationPayload.fromRemoteMessage(message);
  final event = AppNotificationEvent.backgroundReceived(payload: payload);
  await PushNotificationService.persistPendingBackgroundEvent(event);
  await PushNotificationService.persistLastEvent(event);
  PushNotificationService.log(
    'Stored background push event. messageId=${payload.messageId}',
  );
}

class AppNotificationPayload {
  const AppNotificationPayload({
    required this.messageId,
    required this.title,
    required this.body,
    required this.data,
    required this.sentTimeEpochMillis,
    required this.from,
    required this.category,
  });

  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final int? sentTimeEpochMillis;
  final String? from;
  final String? category;

  factory AppNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final normalizedData = Map<String, dynamic>.from(message.data);
    return AppNotificationPayload(
      messageId: message.messageId,
      title: notification?.title ?? normalizedData['title']?.toString(),
      body: notification?.body ?? normalizedData['body']?.toString(),
      data: normalizedData,
      sentTimeEpochMillis: message.sentTime?.millisecondsSinceEpoch,
      from: message.from,
      category: normalizedData['type']?.toString() ??
          normalizedData['category']?.toString(),
    );
  }

  factory AppNotificationPayload.fromJson(Map<String, dynamic> json) {
    return AppNotificationPayload(
      messageId: json['messageId'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      sentTimeEpochMillis: (json['sentTimeEpochMillis'] as num?)?.toInt(),
      from: json['from'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageId': messageId,
      'title': title,
      'body': body,
      'data': data,
      'sentTimeEpochMillis': sentTimeEpochMillis,
      'from': from,
      'category': category,
    };
  }
}

enum AppNotificationEventType {
  foregroundReceived,
  backgroundReceived,
  openedApp,
  launchedApp,
  localNotificationTap,
}

class AppNotificationEvent {
  const AppNotificationEvent({
    required this.type,
    required this.payload,
    required this.occurredAtEpochMillis,
  });

  final AppNotificationEventType type;
  final AppNotificationPayload payload;
  final int occurredAtEpochMillis;

  factory AppNotificationEvent.foregroundReceived({
    required AppNotificationPayload payload,
  }) {
    return AppNotificationEvent(
      type: AppNotificationEventType.foregroundReceived,
      payload: payload,
      occurredAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory AppNotificationEvent.backgroundReceived({
    required AppNotificationPayload payload,
  }) {
    return AppNotificationEvent(
      type: AppNotificationEventType.backgroundReceived,
      payload: payload,
      occurredAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory AppNotificationEvent.openedApp({
    required AppNotificationPayload payload,
  }) {
    return AppNotificationEvent(
      type: AppNotificationEventType.openedApp,
      payload: payload,
      occurredAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory AppNotificationEvent.launchedApp({
    required AppNotificationPayload payload,
  }) {
    return AppNotificationEvent(
      type: AppNotificationEventType.launchedApp,
      payload: payload,
      occurredAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory AppNotificationEvent.localNotificationTap({
    required AppNotificationPayload payload,
  }) {
    return AppNotificationEvent(
      type: AppNotificationEventType.localNotificationTap,
      payload: payload,
      occurredAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory AppNotificationEvent.fromJson(Map<String, dynamic> json) {
    return AppNotificationEvent(
      type: AppNotificationEventType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AppNotificationEventType.foregroundReceived,
      ),
      payload: AppNotificationPayload.fromJson(
        Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      ),
      occurredAtEpochMillis: (json['occurredAtEpochMillis'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'payload': payload.toJson(),
      'occurredAtEpochMillis': occurredAtEpochMillis,
    };
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<AppNotificationEvent> _eventsController =
      StreamController<AppNotificationEvent>.broadcast();
  static StreamSubscription<RemoteMessage>? _onMessageSubscription;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  static bool _initialized = false;

  static Stream<AppNotificationEvent> get events => _eventsController.stream;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    log('Initializing push notification service...');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await _requestPermission();
    await _configureForegroundPresentation();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    _listenToForegroundMessages();
    _listenToNotificationOpens();
    await _emitPendingBackgroundEventIfAny();
    await _handleInitialMessage();
    log('Push notification service is ready.');
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    );

    final androidPlugin =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _kAndroidNotificationChannelId,
          _kAndroidNotificationChannelName,
          description: _kAndroidNotificationChannelDescription,
          importance: Importance.max,
        ),
      );
    }
  }

  static Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    log('Notification permission status: ${settings.authorizationStatus}');
  }

  static Future<void> _configureForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _listenToForegroundMessages() {
    _onMessageSubscription ??= FirebaseMessaging.onMessage.listen(
      (message) async {
        final payload = AppNotificationPayload.fromRemoteMessage(message);
        final event = AppNotificationEvent.foregroundReceived(payload: payload);
        await persistLastEvent(event);
        _eventsController.add(event);
        log('Foreground push received. messageId=${payload.messageId}');

        if (defaultTargetPlatform == TargetPlatform.android) {
          await _showForegroundNotification(payload);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        log('Foreground push listener error: $error');
        debugPrint('[PUSH NOTIFICATIONS] $stackTrace');
      },
    );
  }

  static void _listenToNotificationOpens() {
    _onMessageOpenedAppSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen(
      (message) async {
        final payload = AppNotificationPayload.fromRemoteMessage(message);
        final event = AppNotificationEvent.openedApp(payload: payload);
        await persistLastEvent(event);
        _eventsController.add(event);
        log('Notification tap reopened app. messageId=${payload.messageId}');
      },
      onError: (Object error, StackTrace stackTrace) {
        log('Notification open listener error: $error');
        debugPrint('[PUSH NOTIFICATIONS] $stackTrace');
      },
    );
  }

  static Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) {
      return;
    }

    final payload = AppNotificationPayload.fromRemoteMessage(message);
    final event = AppNotificationEvent.launchedApp(payload: payload);
    await persistLastEvent(event);
    _eventsController.add(event);
    log('App launched from terminated state via notification.');
  }

  static Future<void> _showForegroundNotification(
    AppNotificationPayload payload,
  ) async {
    final title = payload.title?.trim();
    final body = payload.body?.trim();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      log('Skipping local foreground notification because title/body are empty.');
      return;
    }

    await _localNotificationsPlugin.show(
      payload.messageId.hashCode ^ DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kAndroidNotificationChannelId,
          _kAndroidNotificationChannelName,
          channelDescription: _kAndroidNotificationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload.toJson()),
    );
  }

  static Future<void> _handleLocalNotificationResponse(
    NotificationResponse response,
  ) async {
    final rawPayload = response.payload;
    if (rawPayload == null || rawPayload.trim().isEmpty) {
      return;
    }

    try {
      final payload = AppNotificationPayload.fromJson(
        Map<String, dynamic>.from(jsonDecode(rawPayload) as Map),
      );
      final event = AppNotificationEvent.localNotificationTap(payload: payload);
      await persistLastEvent(event);
      _eventsController.add(event);
      log('Foreground local notification tapped.');
    } catch (error, stackTrace) {
      log('Failed to parse local notification payload: $error');
      debugPrint('[PUSH NOTIFICATIONS] $stackTrace');
    }
  }

  static Future<void> _emitPendingBackgroundEventIfAny() async {
    final raw = await SharedPrefHelper.getNullableString(
      SharedPrefKeys.pendingBackgroundNotificationEvent,
    );
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final event = AppNotificationEvent.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      _eventsController.add(event);
      log('Emitted pending background notification event.');
    } catch (error, stackTrace) {
      log('Failed to parse pending background event: $error');
      debugPrint('[PUSH NOTIFICATIONS] $stackTrace');
    } finally {
      await SharedPrefHelper.removeData(
        SharedPrefKeys.pendingBackgroundNotificationEvent,
      );
    }
  }

  static Future<void> persistLastEvent(AppNotificationEvent event) async {
    await SharedPrefHelper.setData(
      SharedPrefKeys.lastPushNotificationEvent,
      jsonEncode(event.toJson()),
    );
  }

  static Future<void> persistPendingBackgroundEvent(
    AppNotificationEvent event,
  ) async {
    await SharedPrefHelper.setData(
      SharedPrefKeys.pendingBackgroundNotificationEvent,
      jsonEncode(event.toJson()),
    );
  }

  static Future<AppNotificationEvent?> getLastStoredEvent() async {
    final raw = await SharedPrefHelper.getNullableString(
      SharedPrefKeys.lastPushNotificationEvent,
    );
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      return AppNotificationEvent.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static void log(String message) {
    debugPrint('[PUSH NOTIFICATIONS] $message');
  }
}
