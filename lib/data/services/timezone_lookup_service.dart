import '../datasources/local/country_local_data_source.dart';

/// Service to lookup timezone from coordinates using the country.json database.
/// For GPS locations, finds the nearest city and uses its timezone.
class TimezoneLookupService {
  final CountryLocalDataSource _countryDataSource;
  List<_CityWithTimezone>? _cities;

  TimezoneLookupService(this._countryDataSource);

  Future<String?> getTimezoneFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    await _loadCitiesIfNeeded();

    if (_cities == null || _cities!.isEmpty) return null;

    // Find the nearest city using simple distance calculation
    _CityWithTimezone? nearest;
    double minDistance = double.infinity;

    for (final city in _cities!) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = city;
      }
    }

    return nearest?.timezone;
  }

  Future<void> _loadCitiesIfNeeded() async {
    if (_cities != null) return;

    try {
      final countries = await _countryDataSource.getAllCountries();

      _cities = [];
      for (final country in countries) {
        for (final city in country.cities) {
          _cities!.add(_CityWithTimezone(
            latitude: city.latitude,
            longitude: city.longitude,
            timezone: city.timezone,
          ));
        }
        // Also add the country itself as a fallback
        _cities!.add(_CityWithTimezone(
          latitude: country.latitude,
          longitude: country.longitude,
          timezone: country.timezone,
        ));
      }
    } catch (e) {
      _cities = [];
    }
  }

  /// Simplified distance calculation for comparison purposes
  /// Uses squared Euclidean distance (faster than Haversine for comparison)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    return dLat * dLat + dLon * dLon;
  }
}

class _CityWithTimezone {
  final double latitude;
  final double longitude;
  final String timezone;

  _CityWithTimezone({
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });
}
