import 'package:prayer_times/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.description,
    required super.timestamp,
    required super.type,
    required super.isRead,
    super.actionUrl,
    super.imageUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
      actionUrl: json['actionUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    timestamp,
    type,
    isRead,
    actionUrl,
    imageUrl,
  ];

  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    String? actionUrl,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
