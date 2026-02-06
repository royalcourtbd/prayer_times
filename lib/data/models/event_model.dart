import 'package:prayer_times/domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.title,
    required super.description,
    required super.holidayType,
    required super.date,
    required super.colorHex,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      title: json['title'] as String,
      description: json['description'] as String,
      holidayType: json['holidayType'] as String,
      date: json['date'] as String,
      colorHex: json['colorHex'] as String,
    );
  }

  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      title: entity.title,
      description: entity.description,
      holidayType: entity.holidayType,
      date: entity.date,
      colorHex: entity.colorHex,
    );
  }

  factory EventModel.fromFirestore(Map<String, dynamic> data) {
    return EventModel(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      holidayType: data['holiday_type'] ?? '',
      date: data['date'] ?? '',
      colorHex: data['color'] ?? '#FF4CAF50',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'holidayType': holidayType,
      'date': date,
      'colorHex': colorHex,
    };
  }

  @override
  List<Object?> get props => [title, description, holidayType, date, colorHex];
}
