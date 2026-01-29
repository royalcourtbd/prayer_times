import 'package:prayer_times/core/base/base_entity.dart';

class LocationEntity extends BaseEntity {
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? timezone; // IANA timezone identifier (e.g., "Asia/Dhaka")

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.timezone,
  });

  @override
  List<Object?> get props => [latitude, longitude, placeName, timezone];
}
