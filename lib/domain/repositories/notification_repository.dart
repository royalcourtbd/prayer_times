import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<String, List<NotificationEntity>>> getNotifications();
  Future<Either<String, void>> markAsRead(String id);
  Future<Either<String, void>> clearAll();
  Future<Either<String, void>> addNotification(NotificationEntity notification);
  Future<Either<String, void>> deleteNotifications(List<String> ids);
}
