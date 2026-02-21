import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/data/models/notification_model.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';
import 'package:prayer_times/domain/entities/notification_entity.dart';
import 'package:prayer_times/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  final LocalCacheService _cacheService;

  NotificationRepositoryImpl(this._cacheService);

  @override
  Future<Either<String, List<NotificationEntity>>> getNotifications() async {
    try {
      List<NotificationModel> notifications = _loadNotifications();

      // 7 দিনের পুরনো notification auto-cleanup
      final int beforeCount = notifications.length;
      notifications = _cleanupOldNotifications(notifications);
      if (notifications.length != beforeCount) {
        await _saveNotifications(notifications);
      }

      // সর্বশেষ notification আগে দেখাবে
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return right(notifications);
    } catch (e) {
      return left('নোটিফিকেশন লোড করতে সমস্যা হয়েছে');
    }
  }

  @override
  Future<Either<String, void>> markAsRead(String id) async {
    try {
      final List<NotificationModel> notifications = _loadNotifications();

      final int index = notifications.indexWhere((n) => n.id == id);
      if (index == -1) return right(null);

      notifications[index] = notifications[index].copyWith(isRead: true);
      await _saveNotifications(notifications);

      return right(null);
    } catch (e) {
      return left('নোটিফিকেশন আপডেট করতে সমস্যা হয়েছে');
    }
  }

  @override
  Future<Either<String, void>> clearAll() async {
    try {
      await _cacheService.deleteData(key: CacheKeys.notifications);
      return right(null);
    } catch (e) {
      return left('নোটিফিকেশন মুছে ফেলতে সমস্যা হয়েছে');
    }
  }

  @override
  Future<Either<String, void>> addNotification(
    NotificationEntity notification,
  ) async {
    try {
      final List<NotificationModel> notifications = _loadNotifications();

      final NotificationModel model = NotificationModel(
        id: notification.id,
        title: notification.title,
        description: notification.description,
        timestamp: notification.timestamp,
        type: notification.type,
        isRead: notification.isRead,
        actionUrl: notification.actionUrl,
        imageUrl: notification.imageUrl,
      );

      notifications.insert(0, model);

      // 7 দিনের পুরনো notification মুছে ফেলা
      final List<NotificationModel> cleaned =
          _cleanupOldNotifications(notifications);
      await _saveNotifications(cleaned);

      return right(null);
    } catch (e) {
      return left('নোটিফিকেশন সংরক্ষণ করতে সমস্যা হয়েছে');
    }
  }

  @override
  Future<Either<String, void>> deleteNotifications(List<String> ids) async {
    try {
      final List<NotificationModel> notifications = _loadNotifications();
      notifications.removeWhere((n) => ids.contains(n.id));
      await _saveNotifications(notifications);
      return right(null);
    } catch (e) {
      return left('নোটিফিকেশন মুছে ফেলতে সমস্যা হয়েছে');
    }
  }

  /// Hive cache থেকে notification list লোড
  List<NotificationModel> _loadNotifications() {
    return catchAndReturn<List<NotificationModel>>(() {
          final String? json = _cacheService.getData<String>(
            key: CacheKeys.notifications,
          );
          if (json == null) return [];

          final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
          return decoded
              .map(
                (e) =>
                    NotificationModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }) ??
        [];
  }

  /// Notification list Hive cache-এ save
  Future<void> _saveNotifications(List<NotificationModel> notifications) async {
    final String json = jsonEncode(
      notifications.map((e) => e.toJson()).toList(),
    );
    await _cacheService.saveData<String>(
      key: CacheKeys.notifications,
      value: json,
    );
  }

  /// 7 দিনের পুরনো notification filter out
  List<NotificationModel> _cleanupOldNotifications(
    List<NotificationModel> notifications,
  ) {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 7));
    return notifications.where((n) => n.timestamp.isAfter(cutoff)).toList();
  }
}
