import 'package:flutter/material.dart';

abstract class NotificationService {
  Future<bool> isNotificationAllowed();

  Future<void> onOpenedFromNotification();

  Future<void> askNotificationPermission({
    required VoidCallback onGrantedOrSkippedForNow,
    required VoidCallback onDenied,
  });

  /// FCM foreground/background message listening সেটআপ
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
  });

  /// App terminated অবস্থায় notification tap থেকে open হলে initial message চেক
  /// Returns {data, title, body} — title/body notification store করতে লাগে
  Future<Map<String, dynamic>?> getInitialMessage();
}
