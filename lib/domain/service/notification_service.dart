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
    required Future<void> Function(Map<String, dynamic> data)
        onNotificationTapped,
  });

  /// App terminated অবস্থায় notification tap থেকে open হলে initial message চেক
  Future<Map<String, dynamic>?> getInitialMessage();
}
