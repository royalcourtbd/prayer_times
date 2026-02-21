import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:app_settings/app_settings.dart';
import 'package:prayer_times/core/external_libs/throttle_service.dart';
import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/core/utility/number_utility.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/data/services/notification/notification_service_information.dart';
import 'package:prayer_times/domain/service/notification_service.dart';
import 'package:prayer_times/presentation/notification/ui/notification_page.dart';
import 'package:prayer_times/presentation/prayer_times.dart';

/// FCM background message handler — top-level function হতে হবে
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await catchFutureOrVoid(() async {
    // Background/terminated state-এ push notification receive হলে
    // System automatically notification দেখায়, আমাদের কিছু করা লাগে না
    logDebugStatic(
      'Background FCM message received: ${message.messageId}',
      'FCMBackground',
    );
  });
}

class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<bool> determineIfNoNeedForPermission() async {
    final bool? noNeedForPermission = await catchAndReturnFuture(() async {
      if (Platform.isIOS) return false;
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 28) return true;
      return false;
    });
    return noNeedForPermission ?? false;
  }

  void requestPermission() async {
    NotificationSettings notificationSettings = await _firebaseMessaging
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
          carPlay: true,
          announcement: true,
          criticalAlert: true,
          provisional: true,
          providesAppNotificationSettings: true,
        );
    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      logDebug('Notification permission granted');
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      logDebug('Notification permission provisional');
    } else {
      showMessage(message: 'Notification permission denied');
      Future.delayed(2.inSeconds, () {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
      });
    }
  }

  @override
  Future<void> askNotificationPermission({
    required VoidCallback onGrantedOrSkippedForNow,
    required VoidCallback onDenied,
  }) async {
    Throttle.throttle(
      'askNotificationPermissionThrottled',
      1.inSeconds,
      () async {
        await catchFutureOrVoid(() async {
          final bool noNeedForPermission =
              await determineIfNoNeedForPermission();
          if (noNeedForPermission) {
            onGrantedOrSkippedForNow();
            return;
          }

          // Use the requestPermission logic here
          NotificationSettings notificationSettings = await _firebaseMessaging
              .requestPermission(
                alert: true,
                badge: true,
                sound: true,
                carPlay: true,
                announcement: true,
                criticalAlert: true,
                provisional: true,
                providesAppNotificationSettings: true,
              );

          if (notificationSettings.authorizationStatus ==
                  AuthorizationStatus.authorized ||
              notificationSettings.authorizationStatus ==
                  AuthorizationStatus.provisional) {
            onGrantedOrSkippedForNow();
          } else {
            onDenied();
          }
        });
      },
    );
  }

  @override
  Future<void> onOpenedFromNotification() async {
    await catchFutureOrVoid(() async {
      // FCM notification tap হলে NotificationPage-এ navigate
      final NavigatorState? navigatorState =
          PrayerTimes.navigatorKey.currentState;
      if (navigatorState == null) return;

      navigatorState.push(
        CupertinoPageRoute(builder: (_) => NotificationPage()),
      );
    });
  }

  @override
  Future<bool> isNotificationAllowed() async {
    return await catchAndReturnFuture<bool>(() async {
          final NotificationSettings settings =
              await _firebaseMessaging.getNotificationSettings();
          final bool isAllowed =
              settings.authorizationStatus == AuthorizationStatus.authorized;
          logDebug('Notification allowed: $isAllowed');
          return isAllowed;
        }) ??
        false;
  }

  @override
  Future<void> setupFCMListeners({
    required Future<void> Function(
      Map<String, dynamic> data,
      String? title,
      String? body,
    ) onMessageReceived,
    required Future<void> Function(
      Map<String, dynamic> data,
      String? title,
      String? body,
    ) onNotificationTapped,
  }) async {
    await catchFutureOrVoid(() async {
      // 1. Foreground messages — app open অবস্থায় push আসলে
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await catchFutureOrVoid(() async {
          final String? title = message.notification?.title;
          final String? body = message.notification?.body;
          final Map<String, dynamic> data = message.data;

          // awesome_notifications দিয়ে foreground notification দেখানো
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: DateTime.now().millisecondsSinceEpoch % 2147483647,
              channelKey: pushNotificationChannelKey,
              title: title ?? '',
              body: body ?? '',
              notificationLayout: NotificationLayout.Default,
              category: NotificationCategory.Message,
              wakeUpScreen: true,
              payload: data.map((k, v) => MapEntry(k, v.toString())),
              autoDismissible: true,
            ),
          );

          // Callback — notification storage-এ save করার জন্য
          await onMessageReceived(data, title, body);
        });
      });

      // 2. Background/Terminated — notification tap করে app open করলে
      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) async {
          await catchFutureOrVoid(() async {
            await onNotificationTapped(
              message.data,
              message.notification?.title,
              message.notification?.body,
            );
          });
        },
      );

      logDebug('FCM listeners set up successfully');
    });
  }

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async {
    try {
      final RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage == null) return null;

      // data-র সাথে title/body ও return করো — notification store করতে লাগবে
      return {
        ...initialMessage.data,
        '_title': initialMessage.notification?.title,
        '_body': initialMessage.notification?.body,
      };
    } catch (e) {
      logDebug('Error getting initial message: $e');
      return null;
    }
  }
}
