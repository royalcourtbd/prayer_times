import 'package:geocoding/geocoding.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/data/services/timezone_lookup_service.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';

abstract class LocationRemoteDataSource {
  Future<LocationEntity> getPlaceNameFromCoordinates({
    required double latitude,
    required double longitude,
  });
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final TimezoneLookupService _timezoneLookupService;

  LocationRemoteDataSourceImpl(this._timezoneLookupService);

  @override
  Future<LocationEntity> getPlaceNameFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    // Lookup timezone from coordinates using nearest city
    final String? timezone = await _timezoneLookupService
        .getTimezoneFromCoordinates(latitude, longitude);

    final LocationEntity? result = await catchAndReturnFuture(() async {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final List<String> addressParts = [];

        // Add subLocality if available
        if (place.subLocality?.isNotEmpty == true) {
          addressParts.add(place.subLocality!);
        }

        // Add locality if available
        if (place.locality?.isNotEmpty == true) {
          addressParts.add(place.locality!);
        }

        // If both locality and subLocality are empty, add subAdministrativeArea
        if (addressParts.isEmpty &&
            place.subAdministrativeArea?.isNotEmpty == true) {
          addressParts.add(place.subAdministrativeArea!);
        }

        return LocationEntity(
          latitude: latitude,
          longitude: longitude,
          placeName: addressParts.isEmpty
              ? 'Unknown Place'
              : addressParts.join(', '),
          timezone: timezone,
        );
      } else {
        return LocationEntity(
          latitude: latitude,
          longitude: longitude,
          placeName: 'Unknown Place',
          timezone: timezone,
        );
      }
    });

    // Return default value if the future resulted in an error
    return result ??
        LocationEntity(
          latitude: latitude,
          longitude: longitude,
          placeName: 'Unknown Place',
          timezone: timezone,
        );
  }
}
