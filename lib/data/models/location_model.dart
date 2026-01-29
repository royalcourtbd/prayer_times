import 'package:prayer_times/domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    super.placeName,
    super.timezone,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      placeName: json['placeName'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      placeName: entity.placeName,
      timezone: entity.timezone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'timezone': timezone,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude, placeName, timezone];

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? placeName,
    String? timezone,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
      timezone: timezone ?? this.timezone,
    );
  }
}
