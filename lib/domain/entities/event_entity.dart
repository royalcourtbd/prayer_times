import 'package:prayer_times/core/base/base_entity.dart';

class EventEntity extends BaseEntity {
  final String title;
  final String description;
  final String holidayType;
  final String date;
  final String colorHex;

  const EventEntity({
    required this.title,
    required this.description,
    required this.holidayType,
    required this.date,
    required this.colorHex,
  });

  @override
  List<Object?> get props => [title, description, holidayType, date, colorHex];
}
